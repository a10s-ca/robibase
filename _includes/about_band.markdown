{% if page.band %}

## À propos de [{{ page.band.name }}](https://www.wikidata.org/wiki/{{ page.band.wikidata_id}}), {{ page.band.description }}

{% if page.band.birth_date %}
  Né le {{ page.band.birth_date }}{% if page.band.birth_place%} ({{ page.band.birth_place}}){% endif %}
{% endif %}

{% if page.band.death_date %}
  Décédé(e) le {{ page.band.death_date }}{% if page.band.death_place%} ({{ page.band.death_place}}){% endif %}
{% endif %}

{% if page.band.sex %}
  Pronom: {% if page.band.sex == 'masculin'%}il/lui{% endif %}{% if page.band.sex == 'féminin'%}elle{% endif %}
{% endif %}

{% if page.band.image %}
  {%- for image_url in page.band.image -%}
    ![{{ page.band.name }}]({{ image_url }}){: .align-center}
  {%- endfor -%}
{% endif %}

{%- if page.band.website || page.band.isni || page.band.facebook || page.band.instagram || page.band.twitter %}
  Ailleurs sur le web:
  {%- if page.band.website %}
    [Site web officiel]({{page.band.website}})
  {%- endif %}
  {%- if page.band.isni %}
    {%- for isni in page.band.isni %}
      [ISNI](https://isni.org/isni/{{ isni | replace(" ", "") }})
    {%- endfor %}
  {%- endif %}
  {%- if page.band.facebook %}
    [Facebook](https://www.facebook.com/{{page.band.facebook }})
  {%- endif %}
  {%- if page.band.instagram %}
    [Instagram](https://www.instagram.com/{{page.band.instagram }})
  {%- endif %}
  {%- if page.band.twitter %}
    [Twitter](https://www.twitter.com/{{page.band.twitter }})
  {%- endif %}
{%- endif %}

{%- if page.band.inception %}
  <br/><br/>
  {%- if page.band.location_of_formation %}
    Groupe formé à {{ page.band.location_of_formation }}, {{ page.band.inception }}
  {%- else %}
    Formation du groupe: {{ page.band.inception }}
  {%- endif %}
{%- else %}
  {%- if page.band.location_of_formation %}
    <br/><br/>
    Groupe formé à {{ page.band.location_of_formation }}
  {%- endif %}
{%- endif %}

{% if page.band.genre %}
  Genre: {{ page.band.genre }}
{% endif %}

{% if page.band.influenced_by %}
  Influence(s): {{ page.band.influenced_by }}
{% endif %}

{% if page.band.musical_instruments %}
  Instrument(s): {{ page.band.musical_instruments }}
{% endif %}


Manque d'information? [Contribuez ici!](https://www.wikidata.org/wiki/{{ page.band.wikidata_id}})

{% endif %}
