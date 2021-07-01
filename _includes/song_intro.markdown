Interprétation par Damien Robitaille de la chanson _{{ page.title }}_ de {{ page.band.name}}. {% if page.video_date != "" and page.tweet_url != "" %}La vidéo a été [publiée sur Twitter]({{ page.tweet_url }}) le {{ page.video_date }}.{% endif %}

{% unless page.header.video.id == blank %}
{% include video id=page.header.video.id provider="youtube" %}
{% else %}
Nous afficherons la vidéo lorsqu'elle sera disponible sur YouTube. {% if page.video_date != "" and page.tweet_url != "" %}En attendant, elle peut être visionnée [sur Twitter]({{ page.tweet_url }}).{% endif %}.
{% endunless %}
