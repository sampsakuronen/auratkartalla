_Omistettu rakkaalle Ainolle, joka jaksaa kannustaa mua tekemään sitä mistä tykkään - nörttäämään._

# Helsinki snowplow visualization
This app is running at http://www.auratkartalla.com/

This data visualization shows an a map information about wintertime maintenance jobs in the Helsinki region. The snowplow GPS data is collected by [Stara](http://www.hel.fi/stara). The API used is part of [Helsinki Open Data project](http://dev.hel.fi/). Data is collected only from a small portion of all vehicles.

I'm using [Sass](http://sass-lang.com/) with [Compass](http://compass-style.org/) to precompile CSS and [CoffeeScript](http://coffeescript.org/) for JS. I suggest you learn these at [Code School](http://codeschool.com/) ([CoffeeScript](http://coffeescript.codeschool.com/), [Sass](https://www.codeschool.com/courses/assembling-sass)). Front-end is done with [Lo-Dash](https://lodash.com/) and jQuery. This app doesn't have a back-end besides [the Aura-API](https://github.com/City-of-Helsinki/aura/wiki/API). Hosting is provided by [Heroku](http://www.heroku.com).

You can ignore index.php, it's only used to trigger Apache stack on Heroku.


## How to
    gem install compass
    npm install -g coffee-script (Sass 3.4.9 and Compass 1.0.1 tested, Coffee at 1.8.0)
    compass watch .
    coffee -cwo js/ coffee/main.coffee
    Launch a server (for example: python -m SimpleHTTPServer 8000)
    Open in browser: http://localhost:8000/home.html


## Licence
Licence is GPL v3. Please remember attribution and drop me a line: [@sampsakuronen](https://twitter.com/sampsakuronen)


## Links
- [Auratkartalla.com on Twitter](https://twitter.com/auratkartalla)
- [Sampsa Kuronen on Twitter](https://twitter.com/sampsakuronen)
- https://github.com/codeforeurope/aura/wiki/API
- http://dev.hel.fi/
- http://www.hel.fi/stara
