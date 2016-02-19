require 'byebug'
require 'json'
require 'pg'
require 'rubygems'
require 'sinatra'
require 'sinatra/activerecord'
require 'sinatra/cookies'
require_relative 'fake_screenshot'
require_relative 'player'
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

get '/richard/:number_of_results' do
  content_type :json

  screenshots = Screenshot.order("random()").limit(params["number_of_results"])

  screenshots.to_json(:methods => :sonic)
end

post '/play' do
  if params.present?
    session.clear

    players = _setup_players(params)
    params.each do |key, value|
      next if ["minimum_year", "maximum_year"].include?(key) && value == "---"
      session[key] = value
    end
  end

  @current_player_number = session["current_player"].player_number

  begin
    @screenshot = _filter_screenshots
  rescue ActiveRecord::ConnectionNotEstablished
    @screenshot = FakeScreenshot.new
  end

  return erb :index if @screenshot.nil?

  erb :play
end

post '/guess' do
  guess = params[:guess]
  game_title = params[:gameTitle]
  current_player = session["current_player"]

  if guess.downcase == game_title.downcase
    current_player.score += 1
  end
  result = "<p>SCORE #{current_player.score}</p>"

  next_player_number = current_player.player_number + 1
  if next_player_number > session["number_of_players"].to_i
    next_player_number = 1
  end

  session["current_player"] = session["players"].find do |player|
    player.player_number == next_player_number
  end

  result
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

def _setup_players(params)
  players = []
  number_of_players = params["number_of_players"].to_i

  1.upto(number_of_players) do |player_number|
    players << Player.new(player_number)
  end

  session["current_player"] = players.first
  session["players"] = players
end


_connect_to_database
