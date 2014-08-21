require 'csv'
require 'awesome_print'
require 'httparty'
require 'ruby-progressbar'
require 'sequel'
require 'parallel'
require 'debugger'

DB = Sequel.connect("postgres://localhost/github-data-challenge", :max_connections=>20)
DB.extension(:pg_streaming)

$location_cache_filename = "location_cache.json"
$batch_size = 50000
$location_cache = JSON.parse( IO.read($location_cache_filename) )
$total_network_calls = 0

def save_location_cache
  File.open($location_cache_filename,"w") do |f|
    f.write($location_cache.to_json)
  end
end

def geocode(place)
  unless $location_cache[place]
    begin
      resp = HTTParty.get("http://www.mapquestapi.com/geocoding/v1/address?location=#{URI.escape place}&maxResults=1&key=Fmjtd%7Cluur25uyn9%2Ca0%3Do5-9w70hw").body
      a = JSON.parse(resp)
      $total_network_calls += 1
    rescue
      ap place
      ap resp
      ap a
      return nil
    end
    if a
      a = a["results"].first["locations"].first
      begin
        $location_cache[place] = {lat: a["latLng"]["lat"].to_f, lng: a["latLng"]["lng"].to_f, name: place}
      rescue
        ap place
        ap resp
        ap a
        return nil
      end
    else
      $location_cache[place] = {error: "Could not find location"}
    end
  end
  $location_cache[place]
end

$progress_bar = ProgressBar.create(:format => '%a, %e %bᗧ%i %p%% %t', :progress_mark  => ' ', :remainder_mark => '･', :title => "Processing", :starting_at => 0, :total => $batch_size, :throttle_rate => 1)

def update_location(commit)
  return if commit[:lat]
  geolocation = geocode(commit[:location])
  return unless geolocation
  DB[:datas].where(id: commit[:id]).update lat: geolocation["lat"], lng: geolocation["lng"]
  $progress_bar.increment
  save_location_cache if ($progress_bar.progress % 10000) == 0
end




Parallel.each(DB[:datas].where("lat IS NULL").limit($batch_size), :in_threads => 20) {|commit| update_location commit }
ap "Total network calls: #{$total_network_calls}"
