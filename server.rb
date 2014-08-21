require 'sinatra'
require 'coffee-script'

get '/' do
  File.read(File.join('public', 'index.html'))
end
get '/application.js' do
  coffee :application
end