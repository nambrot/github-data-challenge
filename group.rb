require 'csv'
require 'awesome_print'
require 'httparty'
require 'ruby-progressbar'
require 'sequel'
require 'parallel'
require 'debugger'
require 'thread/pool'

progress_bar = ProgressBar.create(:format => '%a, %e %bᗧ%i %p%% %t', :progress_mark  => ' ', :remainder_mark => '･', :title => "Processing", :starting_at => 0, :total => 2781790, :throttle_rate => 1)

by_datetime = {}
by_point = {}

CSV.foreach("csvs/normalized_over_80.csv") do |row|
  progress_bar.increment
  # by_datetime_array = by_datetime[row[2]] || []
  # by_datetime_array << {t: row[0].to_f, g: row[1].to_f, c: row[3].to_f.round(2), m: row[5].to_i}
  # by_datetime[row[2]] = by_datetime_array
  
  by_point_hash = by_point["#{row[0]}#{row[1]}"] || {m: row[5].to_i, t: row[0].to_i, g: row[1].to_i}
  by_point_hash[row[2]] = row[3].to_f.round(2)
  by_point["#{row[0]}#{row[1]}"] = by_point_hash
end

File.open("csvs/by_point_hash.json","w") do |f|
  f.write(by_point.to_json)
end