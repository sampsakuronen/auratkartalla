BASE_URL = 'http://dev.stadilumi.fi/api/v1/snowplow/'
map = undefined

initializeGoogleMaps = ()->
  mapOptions =
    center: new google.maps.LatLng(60.193084, 24.940338)
    zoom: 12
    disableDefaultUI: true
  styles = [
    "elementType": "labels"
    "stylers": [ "visibility": "off" ]
  ,
    "stylers": [
      { "invert_lightness": true }
      { "hue": "#00e5ff" }
      { "weight": 0.4 }
    ]
  ]
  map = new google.maps.Map(document.getElementById("map-canvas"),
      mapOptions)
  map.setOptions({styles: styles})

dropMapMarker = (lat, lng) ->
  snowPlowMarker =
    path: 'M10 10 H 90 V 90 H 10 L 10 10'
    fillColor: '#DF740C'
    fillOpacity: 0.8
    strokeColor: "#DF740C"
    strokeOpacity: 0.8
    strokeWeight: 4
    scale: 0.01

  marker = new google.maps.Marker(
    position: new google.maps.LatLng(lat, lng)
    map: map
    icon: snowPlowMarker
  )

addMapLine = (coords) ->
  polyline = new google.maps.Polyline(
    path: []
    geodesic: true
    strokeColor: "#f2e35e"
    strokeOpacity: 1.0
    strokeWeight: 2
  )

  i = 0
  while i < legs.length
    steps = legs[i].steps
    j = 0
    while j < steps.length
      nextSegment = google.maps.geometry.encoding.decodePath(steps[j].polyline.points)
      k = 0
      while k < nextSegment.length
        polyline.getPath().push nextSegment[k]
        k++
      j++
    i++

  polyline.setMap map

$(document).ready ->
  getPlowPositionList = (callback)->
    plowPositions = Bacon.fromPromise($.getJSON(BASE_URL + '?callback=?'))
    plowPositions.onValue((json)-> callback(json))
  getPlowHistoryList = (id, callback)->
    plowPositions = Bacon.fromPromise($.getJSON(BASE_URL + '?history=500&callback=?'))
    plowPositions.onValue((json)-> callback(json))

  createPlowTrail = ->

  createPlowPaths = (json)->
    _.each(json, (x)->
      dropMapMarker(x.last_loc.coords[1], x.last_loc.coords[0])
      getPlowHistoryList(x.id, (json)-> createPlowTrail(x.id))
    )


  getPlowPositionList((json)-> createPlowPaths(json))
  initializeGoogleMaps()






console.log '  _________                            .__                       \n
 /   _____/ ____   ______  _  ________ |  |   ______  _  ________\n
 \\_____  \\ /    \\ /  _ \\ \\/ \\/ /\\____ \\|  |  /  _ \\ \\/ \\/ /  ___/\n
 /        \\   |  (  <_> )     / |  |_> >  |_(  <_> )     /\\___ \\ \n
/_______  /___|  /\\____/ \\/\\_/  |   __/|____/\\____/ \\/\\_//____  >\n
        \\/     \\/ .__           |__|     .__  .__             \\/   .___   \n
            ___  _|__| ________ _______  |  | |__|_______ ____   __| _/\n
   Sampsa   \\  \\/ /  |/  ___/  |  \\__  \\ |  | |  \\___   // __ \\ / __ | \n
    Kuronen  \\   /|  |\\___ \\|  |  // __ \\|  |_|  |/    /\\  ___// /_/ | \n
      2014    \\_/ |__/____  >____/(____  /____/__/_____ \\\\___  >____ | \n
                          \\/           \\/              \\/    \\/     \\/\n
               https://github.com/sampsakuronen/snowplow-visualization'
