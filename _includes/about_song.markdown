{% if page.song %}

## À propos de [{{ page.song.name }}](https://www.wikidata.org/wiki/{{ page.song.wikidata_id}}), {{ page.song.description }}

{% if page.song.composer %}
  Composée par {{ page.song.composer }}.
{% endif %}

{% if page.song.lyrics_by %}
  Paroles par {{ page.song.lyrics_by }}.
{% endif %}

{% if page.song.publishing_date %}
  Date de publication: {{ page.song.publishing_date }}
{% endif %}

{% if page.song.part_of %}
  De l'album: {{ page.song.part_of }}
{% endif %}

{% if page.song.disc_label %}
  Du label: {{ page.song.disc_label }}
{% endif %}

{% if page.song.genre %}
  Genre: {{ page.song.genre }}
{% endif %}

{% if page.song.youtube_video %}
  Voir une autre version:
  {% for video_id in page.song.youtube_video %}
    {% include video id=video_id provider="youtube" %}
  {% endfor %}
{% endif %}


Manque d'information? [Contribuez ici!](https://www.wikidata.org/wiki/{{ page.song.wikidata_id}})
{: .notice}

{%- endif -%}
