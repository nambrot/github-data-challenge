$ ->
  window.data = {}
  window.time = 12
  iconFromSizeAndIntensity = (size, intensity) ->
    log = (number, base = 1.5) ->
      Math.log(number) / Math.log(base)

    L.divIcon className: 'foo-marker', iconSize: new L.Point(log(size) * 1.5, log(size) * 1.5), html: "<div style='background-color: rgba(0,0,100,#{intensity}); height: 100%; width: 100%;)'></div>"

  class Map
    el: $('<div class="map"></div>')
    
    load: ->
      @map = L.map(@el[0]).setView([51.505, -0.09], 2)
      L.tileLayer('http://{s}.tile.osm.org/{z}/{x}/{y}.png', {
          attribution: '&copy; <a href="http://osm.org/copyright">OpenStreetMap</a> contributors'
      }).addTo(@map)

      @layer = new L.MarkerClusterGroup 
        maxClusterRadius: 20
        singleMarkerMode: true
        iconCreateFunction: (cluster) ->
          size = _.reduce cluster.getAllChildMarkers(), ((memo, marker) -> (memo  + marker.options.data.m)), 0
          average_itensity = _.reduce(cluster.getAllChildMarkers(), ((memo, marker) -> ( memo + (marker.options.data[window.time] || 0) * marker.options.data.m)), 0) / size

          iconFromSizeAndIntensity(size, average_itensity)

      @layer.addTo @map
    setHeatMap: (datetime_bucket) ->
      window.time = datetime_bucket
      map.layer._featureGroup.eachLayer (cluster) ->
        if cluster instanceof L.MarkerCluster
          cluster._updateIcon()
  
  window.map = new Map
  $("#maps").append map.el
  map.load()

  $('#timeSlider').on "input change", (evt) ->
    hour = Math.floor(evt.target.value/6)
    minute = evt.target.value - hour * 6
    datetime_bucket = hour + minute * 0.1
    $("#time").text "#{hour}:#{minute}0"
    map.setHeatMap datetime_bucket

  $.getJSON "/by_point_hash.json", (evt) ->
    window.data = evt 
    # .map (value, key) ->
    #   [
    #     key,
    #     _.map value, (point) ->
    #       L.marker [point.t, point.g], icon: iconFromSizeAndIntensity(point.m, point.c), data: point
    #   ]
    # .object()
    # .value()
    
    map.layer.addLayers _.map _.values(evt), (v) ->
      L.marker [v.t, v.g], icon: iconFromSizeAndIntensity(100,0.5), data: v
    
    