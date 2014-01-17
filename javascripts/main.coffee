snowAPI = 'http://dev.stadilumi.fi/api/v1/snowplow/'
map = undefined

initializeGoogleMaps = ()->
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
  ,
    "featureType": "road.arterial",
    "stylers": [{ "color": "#00bbff" }]
  ]
  map = new google.maps.Map(document.getElementById("map-canvas"), mapOptions)
  map.setOptions({styles: styles})

dropMapMarker = (lat, lng) ->
  snowPlowMarker =
    path: "M10 10 H 90 V 90 H 10 L 10 10"
    fillColor: "#ff4e00"
    strokeColor: "#ff4e00"
    strokeWeight: 8
    scale: 0.01

  marker = new google.maps.Marker(
    position: new google.maps.LatLng(lat, lng)
    map: map
    icon: snowPlowMarker
  )

addMapLine = (coords) ->
  # console.log coords
  polylinePath = _.reduce(coords.history, ((accu, x)->
    accu.push(new google.maps.LatLng(x.coords[1], x.coords[0]))
    accu), [])

  polyline = new google.maps.Polyline(
    path: polylinePath
    geodesic: true
    strokeColor: "#ff4e00"
    strokeWeight: 2
  )

  polyline.setMap map


$(document).ready ->
  getActivePlows = (callback)->
    plowPositions = Bacon.fromPromise($.getJSON(snowAPI + '?since=2hours+ago&callback=?'))
    plowPositions.onValue((json)-> callback(json))
    plowPositions.onError((error)-> console.error("Failed to fetch active snowplows: #{JSON.stringify(error)}"))

  createPlowTrail = (plowId)->
    plowPositions = Bacon.fromPromise($.getJSON(snowAPI + plowId + '?history=50&callback=?'))
    plowPositions.onValue((json)-> addMapLine(json))
    plowPositions.onError((error)-> console.error("Failed to create snowplow trail for plow #{plowId}: #{error}"))

  createPlowsOnMap = (json)->
    _.each(json, (x)->
      dropMapMarker(x.last_loc.coords[1], x.last_loc.coords[0])
      createPlowTrail(x.id)
    )


  getActivePlows((json)-> createPlowsOnMap(json))
  initializeGoogleMaps()






# console.log("%c
#                                                                                \n
#       _________                            .__                                 \n
#      /   _____/ ____   ______  _  ________ |  |   ______  _  ________          \n
#      \\_____  \\ /    \\ /  _ \\ \\/ \\/ /\\____ \\|  |  /  _ \\ \\/ \\/ /  ___/          \n
#      /        \\   |  (  <_> )     / |  |_> >  |_(  <_> )     /\\___ \\           \n
#     /_______  /___|  /\\____/ \\/\\_/  |   __/|____/\\____/ \\/\\_//____  >          \n
#             \\/     \\/ .__           |__|     .__  .__             \\/   .___    \n
#                 ___  _|__| ________ _______  |  | |__|_______ ____   __| _/    \n
#         Sampsa  \\  \\/ /  |/  ___/  |  \\__  \\ |  | |  \\___   // __ \\ / __ |     \n
#         Kuronen  \\   /|  |\\___ \\|  |  // __ \\|  |_|  |/    /\\  ___// /_/ |     \n
#             2014  \\_/ |__/____  >____/(____  /____/__/_____ \\\\___  >____ |     \n
#                               \\/           \\/              \\/    \\/     \\/     \n
#                   https://github.com/sampsakuronen/snowplow-visualization      \n
#                                                                                ", 'background: #001e29; color: #00bbff')
