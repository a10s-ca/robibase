{% assign this_day = "now" | date: "%j" %}
{% assign this_year = "now" | date: "%Y" %}
{% assign start_day = this_day | minus:10 %}
{% assign end_day = this_day | plus:30 %}

{% assign anniversaries_by_yday = site.data.anniversaries | sort: "yday" %}
{% for anniversary in anniversaries_by_yday | sort: "yday" %}
  {%- if anniversary.yday and (anniversary.yday >= start_day) and (anniversary.yday <= end_day) %}

{%- if anniversary.type == "death_date" %}
{{ anniversary.anniversary_day }} {{ anniversary.year }}: décès de [{{ anniversary.band }}](/categories/#{{ anniversary.band_slug }}) (il y a {{ this_year | minus:anniversary.year }} ans).
{%- endif %}

{%- if anniversary.type == "birth_date" %}
{{ anniversary.anniversary_day }} {{ anniversary.year }}: naissance de [{{ anniversary.band }}](/categories/#{{ anniversary.band_slug }}) (il y a {{ this_year | minus:anniversary.year }} ans).
{%- endif %}

{%- if anniversary.type == "inception" %}
{{ anniversary.anniversary_day }} {{ anniversary.year }}: fondation de [{{ anniversary.band }}](/categories/#{{ anniversary.band_slug }}) (il y a {{ this_year | minus:anniversary.year }} ans).
{%- endif %}

{%- if anniversary.type == "publishing_date" %}
{{ anniversary.anniversary_day }} {{ anniversary.year }}: publication de [{{ anniversary.song }}]({{ anniversary.record_url }}) (il y a {{ this_year | minus:anniversary.year }} ans).
{%- endif %}

  {%- endif %}
{% endfor %}
