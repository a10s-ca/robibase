---
layout: single
title: Par caractéristiques
permalink: /par-caracteristiques/
---

{% for tag in site.tags %}
  {% assign tag_word = tag[0] %}
  {% assign emoji = site.data.emojis.tags[tag_word] %}
  [{{ emoji }} {{ tag_word }}](/caracteristiques/{{tag_word}})
{% endfor %}
