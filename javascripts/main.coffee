snowAPI = "http://dev.hel.fi/auranew/v1/snowplow/"
activePolylines = []
map = null

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

getPlowJobColor = (job)->
  switch job
    when "kv" then "#84ff00"
    when "au" then "#f2c12e"
    when "su" then "#d93425"
    when "hi" then "#ffffff"
    else "#6c00ff"

addMapLine = (plowData, plowJobId)->
  plowTrailColor = getPlowJobColor(plowJobId)
  polylinePath = _.reduce(plowData, ((accu, x)->
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

displayNotification = (notificationText)->
  $notification = $("#notification")
  $notification.empty().text(notificationText).slideDown(800).delay(5000).slideUp(800)

getActivePlows = (time, callback)->
  $("#load-spinner").fadeIn(400)
  plowPositions = Bacon.fromPromise($.getJSON("#{snowAPI}?since=#{time}&location_history=1"))
  plowPositions.onValue((json)->
    if json.length isnt 0
      callback(time, json)
    else
      displayNotification("Ei näytettävää valitulla ajalla")
    $("#load-spinner").fadeOut(800)
  )
  plowPositions.onError((error)-> console.error("Failed to fetch active snowplows: #{JSON.stringify(error)}"))

createIndividualPlowTrail = (time, plowId, historyData)->
  $("#load-spinner").fadeIn(800)

  plowPositions = Bacon.fromPromise($.getJSON("#{snowAPI}#{plowId}?since=#{time}&temporal_resolution=4"))
  plowPositions.filter((json)-> json.length isnt 0).onValue((json)->
    _.map(json, (oneJobOfThisPlow)-> addMapLine(oneJobOfThisPlow, oneJobOfThisPlow[0].events[0]))
    $("#load-spinner").fadeOut(800)
  )
  plowPositions.onError((error)-> console.error("Failed to create snowplow trail for plow #{plowId}: #{JSON.stringify(error)}"))

createPlowsOnMap = (time, json)->
  _.each(json, (x)->
    createIndividualPlowTrail(time, x.id, json)
  )

populateMap = (time)->
  clearMap()
  getActivePlows("#{time}hours+ago", (time, json)-> createPlowsOnMap(time, json))


$(document).ready ->
  clearUI = ->
    $("#notification").stop(true, false).slideUp(200)
    $("#load-spinner").stop(true, false).fadeOut(200)

  $("#info").addClass("off") if $.cookie("info_closed")

  initializeGoogleMaps(populateMap, 24)

  $("#time-filters li").asEventStream("click").throttle(1000).onValue((e)->
    e.preventDefault()
    clearUI()

    $("#time-filters li").removeClass("active")
    $(e.currentTarget).addClass("active")
    $("#visualization").removeClass("on")

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













console.log("
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
                                                                               ")
console.log("It is nice to see that you want to know how something is made. We are looking for guys like you: http://reaktor.fi/careers/")
