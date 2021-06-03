---
layout: single
title: Statistiques
permalink: /stats/
---

<script src="https://cdnjs.cloudflare.com/ajax/libs/Chart.js/3.3.2/chart.min.js" integrity="sha512-VCHVc5miKoln972iJPvkQrUYYq7XpxXzvqNfiul1H4aZDwGBGC0lq373KNleaB2LpnC2a/iNfE5zoRYmB4TRDQ==" crossorigin="anonymous" referrerpolicy="no-referrer"></script>


## Chanteurs originaux

Pour les {{ site.data.stats.sex.male | plus:site.data.stats.sex.female }} chansons associées à des individus (et pas des groupes), il y a plus d'interprètes originaux qui sont des hommes, que de femmes:

<canvas id="sex" width="400" height="400"></canvas>

<script>
var ctx = document.getElementById('sex').getContext('2d');
var myChart = new Chart(ctx, {
    type: 'pie',
    data: {
        labels: ['Homme', 'Femme'],
        datasets: [
          {
            label: 'Genre des chanteurs',
            data: [{{ site.data.stats.sex.male }}, {{ site.data.stats.sex.female }}],
            backgroundColor: ['blue', 'pink']
          }
        ]
    }
});
</script>


## Dates de publication

La date de publication est disponible pour plusieurs chansons, et nous permet de dresser un histogramme présentant le nombre de chansons interprétées en fonction de leur décennie de publication.

<canvas id="decade_of_song" width="400" height="400"></canvas>

<script>
var ctx = document.getElementById('decade_of_song').getContext('2d');
var myChart = new Chart(ctx, {
    type: 'bar',
    data: {
        labels: ["{{ site.data.stats.decade_of_song.labels | join: '", "' }}"],
        datasets: [
          {
            label: 'Décénie de publication des chansons',
            data: [{{ site.data.stats.decade_of_song.values | join: ", " }}],
            backgroundColor: ['blue']
          }
        ]
    }
});
</script>


## Instruments de musique

Plutôt [piano](/tags/#piano) ou [guitare](/tags/#guitare)? Damien maîtrise les deux, mais semble avoir une préférence... Voici le nombre de vidéos où chacun des instruments est utilisé sans l'autre, ou lorsqu'ils sont tous les deux utilisés.

<canvas id="instruments" width="400" height="400"></canvas>

<script>
var ctx = document.getElementById('instruments').getContext('2d');
var myChart = new Chart(ctx, {
    type: 'bar',
    data: {
        labels: ["{{ site.data.stats.instruments.labels | join: '", "' }}"],
        datasets: [
          {
            label: 'Instrument',
            data: [{{ site.data.stats.instruments.values | join: ", " }}],
            backgroundColor: ['blue']
          }
        ]
    },
    options: {
      indexAxis: 'y',
    }
});
</script>


## Zoo-musico-thérapie

Sammy et Scooby, Boule et Bill, Charlie Brown et Snoopy... l'homme et son meilleur ami forment un duo récurrent dans l'art. Damien et [Suki](/tags/#chien) ne font pas exception. À quel point l'enjoué quadrupède est-il présent dans les vidéos de Damien? La réponse ici.

<canvas id="suki" width="400" height="400"></canvas>

<script>
var ctx = document.getElementById('suki').getContext('2d');
var myChart = new Chart(ctx, {
    type: 'pie',
    data: {
        labels: ['Avec Suki', 'Sans Suki'],
        datasets: [
          {
            label: 'Présence de Suki',
            data: [{{ site.data.stats.suki.present }}, {{ site.data.stats.suki.absent }}],
            backgroundColor: ['blue', 'grey']
          }
        ]
    }
});
</script>
