{% for tag in site.tags %}
  {% if tag[0] == page.title %}
    {% assign emoji = site.data.emojis.tags[page.title] %}

    {% for post in tag[1] %}

<div class="feature__item{% if include.type %}--{{ include.type }}{% endif %}">
  <div class="archive__item">
    {% if post.header.teaser %}
      <div class="archive__item-teaser">
        <img src="{{ post.header.teaser | relative_url }}"
             alt="{% if post.title %}{{ post.title }}{% endif %}">
      </div>
    {% endif %}

    <div class="archive__item-body">
      {% if post.title %}
        <h2 class="archive__item-title">{{ post.title }}</h2>
      {% endif %}

      {% if post.excerpt %}
        <div class="small">
          {{ post.excerpt | markdownify }}
        </div>
      {% endif %}

      {% if post.url %}
        <p><a href="{{ post.url | relative_url }}" class="btn btn--primary">Voir</a></p>
      {% endif %}
    </div>
  </div>
</div>

    {% endfor %}

  {% endif %}
{% endfor %}
