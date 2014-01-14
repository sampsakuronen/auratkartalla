# Auravisualisaatio
This app is running at http://auravisualisaatio.herokuapp.com/.

I'm using [Sass](http://sass-lang.com/) with [Compass](http://compass-style.org/) to precompile CSS and [CoffeeScript](http://coffeescript.org/) for JS. I suggest you learn these at [Code School](http://codeschool.com/) ([CoffeeScript](http://coffeescript.codeschool.com/), [Sass](https://www.codeschool.com/courses/assembling-sass)). This app doesn't have a backend. Front-end is done with [Underscore.js](http://underscorejs.org/) and [Bacon.js](http://baconjs.github.io/).

The snowplow GPS data is presented by [Stara](http://www.hel.fi/stara). The API used is a part of [Helsinki Open Data](http://dev.hel.fi/).

index.php is in this repo only so that Heroku installation works (and I'm too lazy to remove it).

## How to
Install Compass and CoffeeScript (see instructions from Google).
    (install compass and coffeescript)
    compass watch .
    coffee -cw javascrip/main.coffee
    launch a server (for example: python -m SimpleHTTPServer 8000)
    open in browser: http://localhost:8000/home.html

## Links
- https://github.com/codeforeurope/aura/wiki/API
- http://dev.hel.fi/
- http://www.hel.fi/stara

## Licence
Licence is GPL v3.
