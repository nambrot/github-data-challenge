$ ->
  window.data = {}

  class Map
    el: $('<div class="map"></div>')
    load: ->
      @map = L.map(@el[0]).setView([51.505, -0.09], 2)
      L.tileLayer('http://{s}.tile.osm.org/{z}/{x}/{y}.png', {
          attribution: '&copy; <a href="http://osm.org/copyright">OpenStreetMap</a> contributors'
      }).addTo(@map)

      @layer = L.heatLayer [], radius: 30, blur: 2, max: 100, gradient: { 0.2: 'blue', 0.35: 'lime', 0.7: 'red' }
            .addTo(@map);
    setHeatMap: (datetime_bucket) ->
      locations = _.chain(data[datetime_bucket])
                    .values()
                    .filter (val) -> val.location_info
                    .map (val) -> new L.LatLng val.location_info.lat, val.location_info.lng, val.count
                    .value()
      @layer.setLatLngs locations
  
  window.map = new Map
  $("#maps").append map.el
  map.load()

  $('#timeSlider').on "input change", (evt) ->
    hour = Math.floor(evt.target.value/6)
    minute = evt.target.value - hour * 6
    datetime_bucket = hour + minute * 0.1
    $("#time").text "#{hour}:#{minute}0"
    map.setHeatMap datetime_bucket
  $.getJSON "/process.json", (evt) ->
    window.data = evt

    
    