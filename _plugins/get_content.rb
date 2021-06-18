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
STATISTICS_DATA_FILE = '_data/stats.json'
AIRTABLE_BASE_ID = ENV["AIRTABLE_BASE_ID"]
AIRTABLE_API_KEY = ENV["AIRTABLE_API_KEY"]
TAG_FOLDER = 'caracteristiques'

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
      }
    },
    tags: record['Tags'],
    category: record['Nom du groupe'],
    video_date: record['Date'] || record['Date'],
    layout: 'single',
    excerpt: record['Titre'] + ' de ' + record['Nom du groupe'] + ' interprété par Damien Robitaille',
    tweet_url: record['Lien Twitter']
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

  if record['Aperçu vidéo'].present? && record['Aperçu vidéo'].count > 0
    fm[:header][:og_image] = record['Aperçu vidéo'][0]['url']
  end

  YAML.dump(fm.deep_stringify_keys) + "\n---"
end

def build_post_content(record)
  page_content = """
{% include song_intro.markdown %}
{% include video id=\"#{record['ID Youtube']}\" provider=\"youtube\" %}
{% include about_data.markdown %}
{% include about_band.markdown %}
{% include about_song.markdown %}
{% include video_object.markdown %}
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

def build_empty_stats
  {
    sex: {
      male: 0,
      female: 0,
    },
    suki: {
      present: 0,
      absent: 0,
    },
    decade_of_song: {
      '1940': 0,
      '1950': 0,
      '1960': 0,
      '1970': 0,
      '1980': 0,
      '1990': 0,
      '2000': 0,
      '2010': 0,
      '2020': 0,
      'Autres': 0
    },
    instruments: {
      'Piano': 0,
      'Guitare': 0,
      'Les deux': 0
    }
  }
end

def add_stats_for_record(record, statistics)
  if record['Données du groupe (JSON)'].present?
    band_info = JSON.parse(record['Données du groupe (JSON)'], symbolize_names: true)
    if s = band_info[:sex]
      statistics[:sex][:male] += 1 if s == 'masculin'
      statistics[:sex][:female] += 1 if s == 'féminin'
    end
  end

  if record['Données du titre (JSON)'].present?
    song_info = JSON.parse(record['Données du titre (JSON)'], symbolize_names: true)
    if song_info[:publishing_date]
      year = fix_date(song_info[:publishing_date])[0,4].to_i
      decade = year.to_s[0,3] + '0'
      if year >= 1940 and year < 2030
        statistics[:decade_of_song][decade.to_sym] += 1
      else
        statistics[:decade_of_song]['Autres'.to_sym] += 1
      end
    end
  end

  if record['Tags'].present?
    if record['Tags'].include?('chien')
      statistics[:suki][:present] += 1
    else
      statistics[:suki][:absent] += 1
    end

    statistics[:instruments]['Guitare'.to_sym] += 1 if record['Tags'].include?('guitare') && !record['Tags'].include?('piano')
    statistics[:instruments]['Piano'.to_sym] += 1 if record['Tags'].include?('piano') && !record['Tags'].include?('guitare')
    statistics[:instruments]['Les deux'.to_sym] += 1 if record['Tags'].include?('piano') && record['Tags'].include?('guitare')
  end

  statistics
end

# some stats will be easier to convert to charts if they are properly formatted
def reformat_statistics(statistics)
  [:decade_of_song, :instruments].each do |stat|
    statistics[stat] = {
      labels: statistics[stat].map { |k, v| k },
      values: statistics[stat].map { |k, v| v }
    }
  end
  statistics
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
  statistics = build_empty_stats
  tags = []

  # create video pages from Airtable data
  records.each do |record|
    video_date = record['Date du tweet'] || record['Date']
    filename = "#{VIDEOS_FOLDER}/#{video_date}-#{record.id.to_s}.md"
    record['url'] = '/videos/' + video_date.gsub('-', '/') + '/' + slugify(record['Titre'])
    File.write(filename, record_to_jekyll_post(record))
    more_anniversaries = get_anniversaries(record)
    more_anniversaries.each do |new_a|
      anniversaries.push(new_a) unless anniversaries.any? { |a| a[:band] == new_a[:band] && a[:type] == new_a[:type] }
      # this is to avoid duplicates, as there may be many records from the same band, leading to duplicates in anniversaries
    end
    statistics = add_stats_for_record(record, statistics)
    tags.push(record['Tags'])
  end

  # save data for anniversaries, stats and tag pages
  File.write(ANNIVERSARIES_DATA_FILE, JSON.pretty_generate(anniversaries))
  File.write(STATISTICS_DATA_FILE, JSON.pretty_generate(reformat_statistics(statistics)))
  tags.flatten.uniq.each { |tag| File.write(TAG_FOLDER + '/' + tag + '.markdown', tag_page(tag)) }
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

def tag_page(tag)
  """---
title: #{tag}
layout: single
---

{% include posts_by_tag.markdown %}
"""
end

def create_index(records)
  # make sure to delete current create_index
  File.delete(INDEX_PAGE) if File.exists?(INDEX_PAGE)

  latest_records = records.select { |r| r['Date du tweet'].present? && r['Aperçu vidéo'].present? }.sort { |r1, r2| Date.parse(r1['Date du tweet']) - Date.parse(r2['Date du tweet']) }

  # create the new index page
  index_page = """---
layout: splash
permalink: /
feature_row:
""" + feature_item(latest_records[-3]) + feature_item(latest_records[-2]) + feature_item(latest_records[-1]) + """---

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
