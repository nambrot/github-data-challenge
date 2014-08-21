require 'csv'
require 'awesome_print'
require 'httparty'
require 'ruby-progressbar'
#group by location

@location_cache = {}
by_datetime = {}
total_network_calls = 0
total_errors = 0
def geocode(place)
  unless @location_cache[place]
    begin
      a = JSON.parse(HTTParty.get("http://www.mapquestapi.com/geocoding/v1/address?location=#{URI.escape place}&maxResults=1&key=Fmjtd%7Cluur25uyn9%2Ca0%3Do5-9w70hw").body)
      total_network_calls++
    rescue
      total_errors++
      return nil
    end
    if a
      a = a["results"].first["locations"].first
      @location_cache[place] = {lat: a["latLng"]["lat"].to_f, lng: a["latLng"]["lng"].to_f, name: place}
    else
      @location_cache[place] = {error: "Could not find location"}
    end
  end
  @location_cache[place]
end

filename = "results-20140818-114721.csv"
progress_bar = ProgressBar.create(:format => '%a %bᗧ%i %p%% %t', :progress_mark  => ' ', :remainder_mark => '･', :title => "Processing", :starting_at => 0, :total => `wc -l #{filename}`.match(/^\s*(\d*)/)[1].to_i)

CSV.foreach("results-20140818-114721.csv") do |row|
  location_name = row[3]
  datetime_bucket = DateTime.parse(row[1]).hour.to_f + (DateTime.parse(row[1]).minute / 10) * 0.1

  datetime_bucket_hash = by_datetime[datetime_bucket] || {}
  location_hash = datetime_bucket_hash[location_name] || {location_info: nil, count: 0}

  location_hash[:location_info] ||= geocode(location_name)
  location_hash[:count] += 1

  datetime_bucket_hash[location_name] = location_hash
  by_datetime[datetime_bucket] = datetime_bucket_hash
  progress_bar.increment
end

File.open("process.json","w") do |f|
  f.write(by_datetime.to_json)
end

ap "Total Network Calls: #{total_network_calls}"
ap "Total Errors: #{total_errors}"

