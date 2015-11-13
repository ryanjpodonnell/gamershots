require 'pg'
require 'rubygems'
require 'sinatra'
require 'sinatra/activerecord'
require_relative 'screenshot'

db = URI.parse(ENV['DATABASE_URL'])
ActiveRecord::Base.establish_connection(
  :adapter  => 'postgresql',
  :host     => db.host,
  :username => db.user,
  :password => db.password,
  :database => db.path[1..-1],
  :encoding => 'utf8'
)

get '/' do
  erb :index
end

post '/play' do
  @screenshot = Screenshot.first

  erb :play
end

get '/filter' do
  erb :filter
end
