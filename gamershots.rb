require 'byebug'
require 'json'
require 'pg'
require 'rubygems'
require 'sinatra'
require 'sinatra/activerecord'
require 'sinatra/cookies'
require 'sinatra/namespace'
require_relative 'fake_screenshot'
require_relative 'screenshot'
require_relative 'screenshot_filterer'
include ScreenshotFilterer

enable :sessions

namespace '/api' do
  get '/sonic' do
    content_type :json

    screenshots = Screenshot.order("random()").limit(100)

    screenshots.to_json(:methods => :sonic)
  end

  get '/screenshot' do
    content_type :json

    _get_screenshot

    @screenshot.to_json
  end
end

get '/' do
  erb :index
end

get '/filter' do
  erb :filter
end

get '/screenshot' do
  _get_screenshot

  return erb :index if @screenshot.nil?

  erb :screenshot
end

def _get_screenshot
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
