snowAPI = 'http://dev.stadilumi.fi/api/v1/snowplow/'

initializeGoogleMaps = (callback)->
  mapOptions =
    center: new google.maps.LatLng(60.193084, 24.940338)
    zoom: 13
    disableDefaultUI: true
  styles = [
    "elementType": "labels"
    "stylers": [ "visibility": "off" ]
  ,
    "stylers": [
      { "invert_lightness": true }
      { "hue": "#00bbff" }
      { "weight": 0.4 }
      { "saturation": 100 }
    ]
  # ,
  #   "featureType": "road.arterial",
  #   "stylers": [{ "color": "#00bbff" }]
  ]
  map = new google.maps.Map(document.getElementById("map-canvas"), mapOptions)
  map.setOptions({styles: styles})
  callback(map)

dropMapMarker = (map, plowJobColor, lat, lng) ->
  snowPlowMarker =
    path: "M10 10 H 90 V 90 H 10 L 10 10"
    fillColor: plowJobColor
    strokeColor: plowJobColor
    strokeWeight: 7
    strokeOpacity: 0.8
    scale: 0.01

  marker = new google.maps.Marker(
    position: new google.maps.LatLng(lat, lng)
    map: map
    icon: snowPlowMarker
  )

addMapLine = (map, plowData, plowTrailColor) ->
  polylinePath = _.reduce(plowData.history, ((accu, x)->
    accu.push(new google.maps.LatLng(x.coords[1], x.coords[0]))
    accu), [])

  polyline = new google.maps.Polyline(
    path: polylinePath
    geodesic: true
    strokeColor: plowTrailColor
    strokeWeight: 2
    strokeOpacity: 0.6
  )

  polyline.setMap map


$(document).ready ->
  getActivePlows = (map, callback)->
    plowPositions = Bacon.fromPromise($.getJSON(snowAPI + '?since=8hours+ago&callback=?'))
    plowPositions.onValue((json)-> callback(map, json))
    plowPositions.onError((error)-> console.error("Failed to fetch active snowplows: #{JSON.stringify(error)}"))

  createPlowTrail = (map, plowId, plowTrailColor)->
    plowPositions = Bacon.fromPromise($.getJSON(snowAPI + plowId + '?since=8hours+ago&callback=?'))
    plowPositions.onValue((json)-> addMapLine(map, json, plowTrailColor))
    plowPositions.onError((error)-> console.error("Failed to create snowplow trail for plow #{plowId}: #{error}"))

  createPlowsOnMap = (map, json)->
    getPlowJobColor = (job)->
      switch job
        when "kv" then "#84ff00"
        when "au" then "#ff6600"
        when "su" then "#ff0113"
        when "hi" then "#cc00ff"
        else "#ffffff"

    _.each(json, (x)->
      plowJobColor = getPlowJobColor(x.last_loc.events[0])
      createPlowTrail(map, x.id, plowJobColor)
      dropMapMarker(map, plowJobColor, x.last_loc.coords[1], x.last_loc.coords[0])
    )

  initializeGoogleMaps((map)-> getActivePlows(map, (map, json)-> createPlowsOnMap(map, json)))
















console.log("%c
                                                                               \n
      _________                            .__                                 \n
     /   _____/ ____   ______  _  ________ |  |   ______  _  ________          \n
     \\_____  \\ /    \\ /  _ \\ \\/ \\/ /\\____ \\|  |  /  _ \\ \\/ \\/ /  ___/          \n
     /        \\   |  (  <_> )     / |  |_> >  |_(  <_> )     /\\___ \\           \n
    /_______  /___|  /\\____/ \\/\\_/  |   __/|____/\\____/ \\/\\_//____  >          \n
            \\/     \\/ .__           |__|     .__  .__             \\/   .___    \n
                ___  _|__| ________ _______  |  | |__|_______ ____   __| _/    \n
        Sampsa  \\  \\/ /  |/  ___/  |  \\__  \\ |  | |  \\___   // __ \\ / __ |     \n
        Kuronen  \\   /|  |\\___ \\|  |  // __ \\|  |_|  |/    /\\  ___// /_/ |     \n
            2014  \\_/ |__/____  >____/(____  /____/__/_____ \\\\___  >____ |     \n
                              \\/           \\/              \\/    \\/     \\/     \n
                  https://github.com/sampsakuronen/snowplow-visualization      \n
                                                                               ", 'background: #001e29; color: #00bbff')
