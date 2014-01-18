snowAPI = 'http://dev.stadilumi.fi/api/v1/snowplow/'
activePolylines = []
activeMarkers = []
map = null

initializeGoogleMaps = (callback, time)->
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
    "stylers": [{ "color": "#00bbff" }, {"weight": 0.1}]
  ]
  map = new google.maps.Map(document.getElementById("map-canvas"), mapOptions)
  map.setOptions({styles: styles})
  callback(time)

dropMapMarker = (plowJobColor, lat, lng) ->
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
  activeMarkers.push(marker)
  marker

addMapLine = (plowData, plowTrailColor) ->
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

  activePolylines.push(polyline)
  polyline.setMap map

clearMap = ->
  _.each(activePolylines, (polyline)-> polyline.setMap(null))
  _.each(activeMarkers, (marker)-> marker.setMap(null))

getActivePlows = (time, callback)->
  plowPositions = Bacon.fromPromise($.getJSON("#{snowAPI}?since=#{time}&callback=?"))
  plowPositions.onValue((json)-> callback(time, json))
  plowPositions.onError((error)-> console.error("Failed to fetch active snowplows: #{JSON.stringify(error)}"))

createPlowTrail = (time, plowId, plowTrailColor)->
  plowPositions = Bacon.fromPromise($.getJSON("#{snowAPI}#{plowId}?since=#{time}&callback=?"))
  plowPositions.onValue((json)-> addMapLine(json, plowTrailColor))
  plowPositions.onError((error)-> console.error("Failed to create snowplow trail for plow #{plowId}: #{error}"))

createPlowsOnMap = (time, json)->
  getPlowJobColor = (job)->
    switch job
      when "kv" then "#84ff00"
      when "au" then "#ff6600"
      when "su" then "#ff0113"
      when "hi" then "#cc00ff"
      else "#ffffff"

  _.each(json, (x)->
    plowJobColor = getPlowJobColor(x.last_loc.events[0])
    createPlowTrail(time, x.id, plowJobColor)
    dropMapMarker(plowJobColor, x.last_loc.coords[1], x.last_loc.coords[0])
  )

populateMap = (time)-> getActivePlows("#{time}hours+ago", (time, json)-> createPlowsOnMap(time, json))


$(document).ready ->
  initializeGoogleMaps(populateMap, 2)

  $("#time-filters li").click((e)->
    e.preventDefault()
    clearMap()
    populateMap($(this).data('time'))
    $("#time-filters li").removeClass("active")
    $(this).addClass("active")
  )

  $("#info").click((e)->
    e.preventDefault()
    $(this).toggleClass("active")
  )








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
