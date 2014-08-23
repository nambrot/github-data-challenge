$ ->
  window.startingTime = moment()
  window.data = {}

  window.getCurrentTime = ->
    val = $('#timeSlider').val()
    hour = Math.floor(val/6)
    minute = val - hour * 6
    displayTime = moment().add('h', hour).add('m', minute * 10)
    return displayTime

  getDateTimeBucket = ->
    time = getCurrentTime()
    time.utc().hour() + time.utc().minute() * 0.1

  sliderValueChanged = () ->
    $("#time").text getCurrentTime().format("HH:mm")
    map.resetTime()
    if markers
      for marker in markers
        marker.setIcon iconFromSizeAndIntensity(marker.options.data.m, (marker.options.data[getDateTimeBucket()] || 0))

  iconFromSizeAndIntensity = (size, intensity = 0) ->
    L.divIcon className: 'foo-marker', iconSize: new L.Point(Math.log(size)/Math.log(1.5) * 1.5, Math.log(size)/Math.log(1.5) * 1.5), html: "<div style='background-color: rgba(0,0,100,#{intensity}); height: 100%; width: 100%;)'></div>"

  class Map
    el: $('<div class="map"></div>')
    load: ->
      @map = L.map(@el[0]).setView([51.505, -0.09], 3)
      @map.locate setView: true, maxZoom: 3
      L.tileLayer('http://{s}.tile.osm.org/{z}/{x}/{y}.png', {
          attribution: '&copy; <a href="http://osm.org/copyright">OpenStreetMap</a> contributors'
      }).addTo(@map)

      @terminator = L.terminator(getCurrentTime().format())
      @terminator.addTo @map
      @layer = new L.MarkerClusterGroup 
        maxClusterRadius: 30
        singleMarkerMode: true
        iconCreateFunction: (cluster) ->
          size = _.reduce cluster.getAllChildMarkers(), ((memo, marker) -> (memo  + marker.options.data.m)), 0
          average_itensity = _.reduce(cluster.getAllChildMarkers(), ((memo, marker) -> ( memo + (marker.options.data[getDateTimeBucket()] || 0) * marker.options.data.m)), 0) / size
          if average_itensity < 0.1
            average_itensity = 0.1
          iconFromSizeAndIntensity(size, average_itensity)

      @layer.addTo @map
    resetTime: () ->
      @terminator.setLatLngs(L.terminator(time: getCurrentTime().valueOf()).getLatLngs());
      @terminator.redraw();
      map.layer._featureGroup.eachLayer (cluster) ->
        if cluster instanceof L.MarkerCluster
          cluster._updateIcon()
  


  $.getJSON "/by_point_hash.json", (evt) ->
    window.map = new Map
    $("#maps").append map.el
    map.load()
    $("#time").text getCurrentTime().format("HH:mm")

    $('#timeSlider').on "input change", _.throttle sliderValueChanged, 300
    window.data = evt
    window.markers = _.map _.values(evt), (v) ->
      L.marker [v.t, v.g], icon: iconFromSizeAndIntensity(v.m, (v[getDateTimeBucket()] || 0)), data: v
    map.layer.addLayers markers
    
    #autoplay
    shouldAutoplay = true
    $('#timeSlider').on "input change", -> (shouldAutoplay = false)
    autoplay = () ->
      if shouldAutoplay
        val = $('#timeSlider').val()
        $("#timeSlider").val (if val is "72" then -71 else ++val)
        sliderValueChanged()
        setTimeout(autoplay, 500)
    autoplay()
    