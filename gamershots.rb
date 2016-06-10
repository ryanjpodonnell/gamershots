require 'byebug'
require 'json'
require 'pg'
require 'rubygems'
require 'sinatra'
require 'sinatra/activerecord'
require 'sinatra/cookies'
require_relative 'fake_screenshot'
require_relative 'screenshot'
require_relative 'screenshot_filterer'
include ScreenshotFilterer

enable :sessions


get '/' do
  erb :index
end

get '/filter' do
  erb :filter
end

get '/sonic/:number_of_results' do
  content_type :json

  screenshots = Screenshot.order("random()").limit(params["number_of_results"])

  screenshots.to_json(:methods => :sonic)
end

get '/screenshot' do
  if params.present?
    session.clear

    params.each do |key, value|
      next if ["minimum_year", "maximum_year"].include?(key) && value == "---"
      session[key] = value
    end
  end

  begin
    @screenshot = _filter_screenshots
  rescue ActiveRecord::ConnectionNotEstablished
    @screenshot = FakeScreenshot.new
  end

  return erb :index if @screenshot.nil?

  erb :screenshot
end

def _connect_to_database
  begin
    db = URI.parse(ENV['DATABASE_URL'])
  rescue URI::InvalidURIError
    return
  end

  ActiveRecord::Base.establish_connection(
    :adapter  => 'postgresql',
    :host     => db.host,
    :username => db.user,
    :password => db.password,
    :database => db.path[1..-1],
    :encoding => 'utf8'
  )
end

_connect_to_database
