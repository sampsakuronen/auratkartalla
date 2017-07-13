const snowAPI = 'https://dev.hel.fi/aura/v1/snowplow/'

var activePolylines = []
var map = null

function initializeGoogleMaps(callback, hours) {
  const helsinkiCenter = new google.maps.LatLng(60.193084, 24.940338)

  const mapOptions = {
    center: helsinkiCenter,
    zoom: 13,
    disableDefaultUI: true,
    zoomControl: true,
    zoomControlOptions: {
      style: google.maps.ZoomControlStyle.SMALL,
      position: google.maps.ControlPosition.RIGHT_BOTTOM
    }
  }

  const styles = [{
    stylers: [
      { invert_lightness: true },
      { hue: '#00bbff' },
      { weight: 0.4 },
      { saturation: 80 }
    ]
  }, {
    featureType: 'road.arterial',
    stylers: [
      { color: '#00bbff' },
      { weight: 0.1 }
    ]
  }, {
    elementType: 'labels',
    stylers: [ {visibility: 'off'} ]
  }, {
    featureType: 'road.local',
    elementType: 'labels.text.fill',
    stylers: [
      { visibility: 'on' },
      { color: '#2b8aa9' }
    ]
  }, {
    featureType: 'administrative.locality',
    stylers: [ {visibility: 'on'} ]
  }, {
    featureType: 'administrative.neighborhood',
    stylers: [ {visibility: 'on'} ]
  }, {
    featureType: 'administrative.land_parcel',
    stylers: [ {visibility: 'on'} ]
  }]

  map = new google.maps.Map(document.getElementById('map-canvas'), mapOptions)
  map.setOptions({styles})

  callback(hours)
}

function getPlowJobColor(job) {
  switch (job) {
    case 'kv': return '#84ff00'
    case 'au': return '#f2c12e'
    case 'su': return '#d93425'
    case 'hi': return '#ffffff'
    case 'hn': return '#00a59b'
    case 'hs': return '#910202'
    case 'ps': return '#970899'
    case 'pe': return '#132bbe'
    default: return '#6c00ff'
  }
}

function addMapLine(plowData, plowJobId) {
  const plowTrailColor = getPlowJobColor(plowJobId)
  const polylinePath = _.reduce(
    plowData,
    function(accu, x) {
      accu.push(new google.maps.LatLng(x.coords[1], x.coords[0]))
      return accu
    },
    [])

  const polyline = new google.maps.Polyline({
    path: polylinePath,
    geodesic: true,
    strokeColor: plowTrailColor,
    strokeWeight: 1.5,
    strokeOpacity: 0.6
  })

  activePolylines.push(polyline)
  polyline.setMap(map)
}

function clearMap() {
  _.each(activePolylines, polyline=> polyline.setMap(null))
}

function displayNotification(notificationText) {
  const $notification = $('#notification')
  $notification.empty()
    .text(notificationText)
    .slideDown(800)
    .delay(5000)
    .slideUp(800)
}

function getActivePlows(hours, callback) {
  $('#load-spinner').fadeIn(400)
  $.getJSON(`${snowAPI}?since=${hours}&location_history=1`)
    .done(function(json) {
      if (json.length !== 0) {
        callback(hours, json)
      } else {
        displayNotification('Ei näytettävää valitulla ajalla')
      }
      $('#load-spinner').fadeOut(800)
    })
    .fail(error=> console.error(`Failed to fetch active snowplows: ${JSON.stringify(error)}`))
}

function createIndividualPlowTrail(hours, plowId, historyData) {
  $('#load-spinner').fadeIn(800)
  $.getJSON(`${snowAPI}${plowId}?since=${hours}&temporal_resolution=4`)
    .done(function(json) {
      if (json.length !== 0) {
        _.map(json, function(oneJobOfThisPlow) {
          const plowHasLastGoodEvent = (oneJobOfThisPlow != null) && (oneJobOfThisPlow[0] != null) && (oneJobOfThisPlow[0].events != null) && (oneJobOfThisPlow[0].events[0] != null)
          if (plowHasLastGoodEvent) {
            addMapLine(oneJobOfThisPlow, oneJobOfThisPlow[0].events[0])
          }
      })
        $('#load-spinner').fadeOut(800)
      }
    })
    .fail(error=> console.error(`Failed to create snowplow trail for plow ${plowId}: ${JSON.stringify(error)}`))
}

function createPlowsOnMap(hours, json) {
  _.each(json, x=> createIndividualPlowTrail(hours, x.id, json))
}


function populateMap(hours) {
  clearMap()
  getActivePlows(`${hours}hours+ago`, (hours, json)=> createPlowsOnMap(hours, json))
}


$(document).ready(function() {
  function clearUI() {
    $('#notification').stop(true, false).slideUp(200)
    $('#load-spinner').stop(true, false).fadeOut(200)
  }

  if (localStorage['auratkartalla.userHasClosedInfo']) { $('#info').addClass('off') }

  initializeGoogleMaps(populateMap, 8)

  $('#time-filters li').on('click', function(e) {
    e.preventDefault()
    clearUI()

    $('#time-filters li').removeClass('active')
    $(e.currentTarget).addClass('active')
    $('#visualization').removeClass('on')

    populateMap($(e.currentTarget).data('hours'))
  })

  $('#info-close, #info-button').on('click', function(e) {
    e.preventDefault()
    $('#info').toggleClass('off')
    localStorage['auratkartalla.userHasClosedInfo'] = true
  })
  $('#visualization-close, #visualization-button').on('click', function(e) {
    e.preventDefault()
    $('#visualization').toggleClass('on')
  })
})



console.log(`\
.................................................................................\n \
.                                                                               .\n \
.      _________                            .__                                 .\n \
.     /   _____/ ____   ______  _  ________ |  |   ______  _  ________          .\n \
.     \\_____  \\ /    \\ /  _ \\ \\/ \\/ /\\____ \\|  |  /  _ \\ \\/ \\/ /  ___/          .\n \
.     /        \\   |  (  <_> )     / |  |_> >  |_(  <_> )     /\\___ \\           .\n \
.    /_______  /___|  /\\____/ \\/\\_/  |   __/|____/\\____/ \\/\\_//____  >          .\n \
.            \\/     \\/ .__           |__|     .__  .__             \\/   .___    .\n \
.                ___  _|__| ________ _______  |  | |__|_______ ____   __| _/    .\n \
.        Sampsa  \\  \\/ /  |/  ___/  |  \\__  \\ |  | |  \\___   // __ \\ / __ |     .\n \
.        Kuronen  \\   /|  |\\___ \\|  |  // __ \\|  |_|  |/    /\\  ___// /_/ |     .\n \
.            2014  \\_/ |__/____  >____/(____  /____/__/_____ \\\\___  >____ |     .\n \
.                              \\/           \\/              \\/    \\/     \\/     .\n \
.                  https://github.com/sampsakuronen/snowplow-visualization      .\n \
.                                                                               .\n \
.................................................................................\n`)
console.log('It is nice to see that you want to know how something is made. We are looking for guys like you: http://reaktor.fi/careers/')
