# Helsinki snowplow visualization
This app is running at http://www.talvityot.com/

I'm using [Sass](http://sass-lang.com/) with [Compass](http://compass-style.org/) to precompile CSS and [CoffeeScript](http://coffeescript.org/) for JS. I suggest you learn these at [Code School](http://codeschool.com/) ([CoffeeScript](http://coffeescript.codeschool.com/), [Sass](https://www.codeschool.com/courses/assembling-sass)). This app doesn't have a back-end. Front-end is done with [Underscore.js](http://underscorejs.org/) and [Bacon.js](http://baconjs.github.io/). Hosting is provided by [Heroku](http://www.heroku.com).

The snowplow GPS data is presented by [Stara](http://www.hel.fi/stara). The API used is part of [Helsinki Open Data](http://dev.hel.fi/).

You can ignore index.php, it's only used to trigger Apache stack on Heroku.


## How to
    Install Compass and CoffeeScript (see instructions from Google)
    compass watch .
    coffee -cw javascrip/main.coffee
    Launch a server (for example: python -m SimpleHTTPServer 8000)
    Open in browser: http://localhost:8000/home.html


## Licence
Licence is GPL v3. Please remember attribution and drop me a line: [@sampsakuronen](https://twitter.com/sampsakuronen)


## Links
- https://github.com/codeforeurope/aura/wiki/API
- http://dev.hel.fi/
- http://www.hel.fi/stara
