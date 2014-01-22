snowAPI = "http://dev.hel.fi/aura/v1/snowplow/"
activePolylines = []
activeMarkers = []
map = null

PLOW_MAX_SPEED = 120

initializeGoogleMaps = (callback, time)->
  helsinkiCenter = new google.maps.LatLng(60.193084, 24.940338)

  mapOptions =
    center: helsinkiCenter
    zoom: 13
    disableDefaultUI: true
    zoomControl: true
    zoomControlOptions:
      style: google.maps.ZoomControlStyle.SMALL
      position: google.maps.ControlPosition.RIGHT_BOTTOM

  styles = [
    "stylers": [
      { "invert_lightness": true }
      { "hue": "#00bbff" }
      { "weight": 0.4 }
      { "saturation": 80 }
    ]
  ,
    "featureType": "road.arterial"
    "stylers": [
      { "color": "#00bbff" }
      { "weight": 0.1 }
    ]
  ,
    "elementType": "labels"
    "stylers": [ "visibility": "off" ]
  ,
    "featureType": "administrative.locality"
    "stylers": [ "visibility": "on" ]
  ,
    "featureType": "administrative.neighborhood"
    "stylers": [ "visibility": "on" ]
  ,
    "featureType": "administrative.land_parcel"
    "stylers": [ "visibility": "on" ]
  ]

  map = new google.maps.Map(document.getElementById("map-canvas"), mapOptions)
  map.setOptions({styles: styles})

  callback(time)

dropMapMarker = (plowJobColor, lat, lng) ->
  snowPlowMarker =
    path: "M10 10 H 90 V 90 H 10 L 10 10"
    fillColor: plowJobColor
    strokeColor: plowJobColor
    strokeWeight: 9
    strokeOpacity: 0.8
    scale: 0.01

  marker = new google.maps.Marker(
    position: new google.maps.LatLng(lat, lng)
    map: map
    icon: snowPlowMarker
  )

  marker.setClickable(false)

  activeMarkers.push(marker)
  marker

getPlowJobColor = (job)->
  switch job
    when "kv" then "#84ff00"
    when "au" then "#f2c12e"
    when "su" then "#d93425"
    when "hi" then "#ffffff"
    else "#6c00ff"

toRad = (x)-> x * Math.PI / 180;

# lat/lng pair to distance (km)
distance = (lat1, lng1, lat2, lng2)->
  R = 6371;
  lat1rad = toRad(lat1)
  lat2rad = toRad(lat2)
  lng1rad = toRad(lng1)
  lng2rad = toRad(lng2)
  x = (lng2rad - lng1rad) * Math.cos((lat1rad + lat2rad) / 2)
  y = (lat2rad - lat1rad)
  Math.sqrt((x * x) + (y * y)) * R

# [1, 2, 3] -> [[1, 2], [2, 3]]
pair = (arr)->
  if arr.length < 2
    []
  else
    _.range(2, arr.length + 1).map((i)->
      arr.slice(i - 2, i))

# [[1, 2], [2, 3]] -> [1, 2, 3]
unpair = (arr)->
  if arr.length < 1
    []
  else
    arr.map(_.first).concat([_.last(_.last(arr))])

msToH = (ms)->
  ms / 3600000

addMapLine = (plowData, plowJobId)->
  plowTrailColor = getPlowJobColor(plowJobId)

  filteredPlowData = unpair(pair(plowData)
    .map((pair)->
      [x1, x2] = pair

      d = distance(x1.coords[1], x1.coords[0], x2.coords[1], x2.coords[0])
      t = msToH(new Date(x2.timestamp) - new Date(x1.timestamp))
      
      {
        speed: d / t,
        pair: pair
      })
    .filter((x)->
      x.speed < PLOW_MAX_SPEED)
    .map((x)-> x.pair))

  polylinePath = _.reduce(filteredPlowData, ((accu, x)->
    accu.push(new google.maps.LatLng(x.coords[1], x.coords[0]))
    accu), [])

  polyline = new google.maps.Polyline(
    path: polylinePath
    geodesic: true
    strokeColor: plowTrailColor
    strokeWeight: 1.5
    strokeOpacity: 0.6
  )

  activePolylines.push(polyline)
  polyline.setMap map

clearMap = ->
  _.map(activePolylines, (polyline)-> polyline.setMap(null))
  _.map(activeMarkers, (marker)-> marker.setMap(null))

displayNotification = (notificationText)->
  $notification = $("#notification")
  $notification.empty().text(notificationText).slideDown(800).delay(5000).slideUp(800)

getActivePlows = (time, callback)->
  $("#load-spinner").fadeIn(400)
  plowPositions = Bacon.fromPromise($.getJSON("#{snowAPI}?since=#{time}"))
  plowPositions.onValue((json)->
    if json.length isnt 0
      callback(time, json)
    else
      displayNotification("Ei näytettävää valitulla ajalla")
    $("#load-spinner").fadeOut(800)
  )
  plowPositions.onError((error)-> console.error("Failed to fetch active snowplows: #{JSON.stringify(error)}"))

createPlowTrail = (time, plowId, historyData)->
  splitPlowDataByJob = (plowData)-> _.groupBy(plowData.history, ((x)-> x.events[0]), [])

  $("#load-spinner").fadeIn(800)
  plowPositions = Bacon.fromPromise($.getJSON("#{snowAPI}#{plowId}?since=#{time}&temporal_resolution=4"))
  plowPositions.filter((json)-> json.length isnt 0).onValue((json)->
    _.map(splitPlowDataByJob(json), (oneJobOfThisPlow)-> addMapLine(oneJobOfThisPlow, oneJobOfThisPlow[0].events[0]))
    $("#load-spinner").fadeOut(800)
  )
  plowPositions.onError((error)-> console.error("Failed to create snowplow trail for plow #{plowId}: #{JSON.stringify(error)}"))

createPlowsOnMap = (time, json)->
  _.each(json, (x)->
    createPlowTrail(time, x.id, json)
    dropMapMarker(getPlowJobColor(x.last_loc.events[0]), x.last_loc.coords[1], x.last_loc.coords[0])
  )

populateMap = (time)->
  clearMap()
  getActivePlows("#{time}hours+ago", (time, json)-> createPlowsOnMap(time, json))


$(document).ready ->
  $("#info").addClass("off") if $.cookie("info_closed")

  initializeGoogleMaps(populateMap, 24)

  $("#time-filters li").asEventStream("click").throttle(1000).onValue((e)->
    e.preventDefault()

    $("#notification").stop(true, false).slideUp(200)
    $("#load-spinner").stop(true, false).fadeOut(200)
    $("#time-filters li").removeClass("active")
    $("#visualization").removeClass("on")
    $(e.currentTarget).addClass("active")

    populateMap($(e.currentTarget).data("hours"))
  )

  $("#info-close, #info-button").asEventStream("click").onValue((e)->
    e.preventDefault()
    $("#info").toggleClass("off")
    $.cookie("info_closed", "true", { expires: 7 })
  )

  $("#visualization-close, #visualization-button").asEventStream("click").onValue((e)->
    e.preventDefault()
    $("#visualization").toggleClass("on")
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
                                                                               ", "background: #001e29; color: #00bbff")
console.log("It is nice to see that you want to know how something is made. We are looking for guys like you: http://reaktor.fi/careers/")
