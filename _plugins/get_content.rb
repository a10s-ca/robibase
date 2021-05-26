require 'airtable'
require 'active_support/all'
require 'fileutils'
require 'dotenv/load'
require 'json'
require 'yaml'
require 'byebug'

POSTS_FOLDER = '_posts'
VIDEOS_FOLDER = '_posts/videos'
INDEX_PAGE = 'index.markdown'
ANNIVERSARIES_DATA_FILE = '_data/anniversaries.json'
AIRTABLE_BASE_ID = ENV["AIRTABLE_BASE_ID"]
AIRTABLE_API_KEY = ENV["AIRTABLE_API_KEY"]

LES_MOIS = ['janvier', 'février', 'mars', 'avril', 'mai', 'juin', 'juillet', 'août', 'septembre', 'octobre', 'novembre', 'décembre']
# apparently Ruby's strftime does not know about French months and I do not want to add an I18n gem just for month names

def slugify(title)
  title.downcase.gsub(' ', '-').gsub(/[^\w-]/, '')
end

# all the following date related functions are needed because dates from Wikidata
# include 00, such as 1950-03-00 or 1936-00-00, which are not valid
# for the Ruby date parser

def fix_date(date_string)
  if date_string
    if date_string.include?('00-00')
      return date_string[1,4]
    elsif date_string.include?('-00')
      return date_string[1,7]
    else
      return Date.parse(date_string[1..-1]).strftime('%Y-%m-%d')
    end
  end
end

def get_year(date_string) # not a good name
  if date_string
    return date_string[1,4].to_i
  end
end

def get_month(date_string)
  if date_string
    if date_string.length >= 8
      m = date_string[6,2].to_i
      return m == 0 ? nil : m
    else
      return nil
    end
  end
end

def get_day(date_string)
  if date_string
    if date_string.length >= 11
      d = date_string[9,2].to_i
      return d == 0 ? nil : d
    else
      return nil
    end
  end
end

def get_yday(date_string)
  if date_string
    if date_string.include?('00-00')
      return nil
    elsif date_string.include?('-00')
      return nil
    else
      return Date.parse(date_string[1..-1]).yday
    end
  end
end

def build_front_matter(record)
  # build front matter
  fm = {
    title: record['Titre'],
    slug: slugify(record['Titre']),
    header: {
      video: {
        id: record['ID Youtube'],
        provider: 'youtube'
      }
    },
    tags: record['Tags'],
    category: record['Nom du groupe'],
    layout: 'single',
  }

  if record['Données du groupe (JSON)'].present?
    fm[:band] = JSON.parse(record['Données du groupe (JSON)'], symbolize_names: true)
    fm[:band][:wikidata_id] = record['ID Wikidata du groupe']

    # fix some formatting issues
    fm[:band][:isni] = fm[:band][:isni].map { |i| i.gsub(' ', '') } if fm[:band] && fm[:band][:isni]
    fm[:band][:inception] = fix_date(fm[:band][:inception]) if fm[:band][:inception]
    fm[:band][:birth_date] = fix_date(fm[:band][:birth_date]) if fm[:band][:birth_date]
    fm[:band][:death_date] = fix_date(fm[:band][:death_date]) if fm[:band][:death_date]
  end

  if record['Données du titre (JSON)'].present?
    fm[:song] = JSON.parse(record['Données du titre (JSON)'], symbolize_names: true)
    fm[:song][:wikidata_id] = record['ID Wikidata du titre']

    # fix some formatting issues
    fm[:song][:publishing_date] = fix_date(fm[:song][:publishing_date]) if fm[:song][:publishing_date]
  end

  YAML.dump(fm.deep_stringify_keys) + "\n---"
end

def build_post_content(record)
  page_content = """
par #{record["Nom du groupe"]}
{% include about_band.markdown %}
{% include about_song.markdown %}
  """
end

def record_to_jekyll_post(record)
  [build_front_matter(record), build_post_content(record)].join("\n")
end

def get_anniversary(base, anniversary_date, anniverary_type)
  res = base.merge({
    type: anniverary_type,
    year: get_year(anniversary_date),
    month: get_month(anniversary_date),
    day: get_day(anniversary_date),
    yday: get_yday(anniversary_date),
  })

  if res[:yday]
    res[:anniversary_day] = res[:day].to_s + " " + LES_MOIS[res[:month]-1]
  end

  return  res
end

def get_anniversaries(record)
  anniversaries = []

  if record['Données du groupe (JSON)'].present?
    band = JSON.parse(record['Données du groupe (JSON)'], symbolize_names: true)
    [:inception, :birth_date, :death_date].each do |dated_property|
      anniversaries.push(get_anniversary({ band: band[:name], record_url: record['url'], band_slug: slugify(band[:name]) }, band[dated_property], dated_property)) if band[dated_property]
    end
  end

  if record['Données du titre (JSON)'].present?
    song = JSON.parse(record['Données du titre (JSON)'], symbolize_names: true)
    [:publishing_date].each do |dated_property|
      anniversaries.push(get_anniversary({ song: song[:name], record_url: record['url'] }, song[dated_property], dated_property)) if song[dated_property]
    end
  end

  return anniversaries
end

def create_posts(records)
  # make sure the posts folder exists
  FileUtils.mkdir(POSTS_FOLDER) unless File.directory?(POSTS_FOLDER)
  FileUtils.mkdir(VIDEOS_FOLDER) unless File.directory?(VIDEOS_FOLDER)

  # delete current video pages
  Dir.foreach(VIDEOS_FOLDER) do |f|
    fn = File.join(VIDEOS_FOLDER, f)
    File.delete(fn) if f != '.' && f != '..'
  end

  anniversaries = []

  # create video pages from Airtable data
  records.each do |record|
    video_date = record['Date']
    filename = "#{VIDEOS_FOLDER}/#{video_date}-#{record.id.to_s}.md"
    record['url'] = '/videos/' + video_date.gsub('-', '/') + '/' + slugify(record['Titre'])
    File.write(filename, record_to_jekyll_post(record))
    more_anniversaries = get_anniversaries(record)
    more_anniversaries.each do |new_a|
      anniversaries.push(new_a) unless anniversaries.any? { |a| a[:band] == new_a[:band] && a[:type] == new_a[:type] }
      # this is to avoid duplicates, as there may be many records from the same band, leading to duplicates in anniversaries
    end
  end

  # save data for anniversaries
  File.write(ANNIVERSARIES_DATA_FILE, JSON.pretty_generate(anniversaries))
end

def feature_item(record)
  """- image_path: #{record['Aperçu vidéo'][0]['url']}
  alt: \"#{record['Titre']}\"
  title: \"#{record['Titre']}\"
  url: \"#{record['url']}\"
  btn_label: \"Voir\"
  btn_class: \"btn--primary btn--small\"
"""
end

def create_index(records)
  # make sure to delete current create_index
  File.delete(INDEX_PAGE) if File.exists?(INDEX_PAGE)

  # create the new index page
  index_page = """---
layout: splash
permalink: /
feature_row:
""" + feature_item(records[-3]) + feature_item(records[-2]) + feature_item(records[-1]) + """---

{% include homepage.markdown %}

"""

  File.write(INDEX_PAGE, index_page)
end

Jekyll::Hooks.register :site, :after_init do
  unless ENV['ROBIBASE_SKIP_IMPORT']
    puts "Starting to import"

    # setup to read from Airtable DB
    client = Airtable::Client.new(AIRTABLE_API_KEY)
    table = client.table(AIRTABLE_BASE_ID, "Vidéos")
    records = table.all
    puts "GOT #{records.length.to_s} records"

    create_posts(records)
    create_index(records)
  else
    puts "Skip importing"
  end
end
