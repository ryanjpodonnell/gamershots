require 'pg'
require 'rubygems'
require 'sinatra'
require 'sinatra/activerecord'
require 'sinatra/cookies'
require 'json'
require_relative 'screenshot'
require_relative 'fake_screenshot'

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
  session.clear if params.present?
  params.each do |key, value|
    next if ["minimum_year", "maximum_year"].include?(key) && value == "---"
    session[key] = value
  end

  begin
    @screenshot = _filter_screenshots
  rescue ActiveRecord::ConnectionNotEstablished
    @screenshot = FakeScreenshot.new
  end

  return erb :index if @screenshot.nil?

  erb :play
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

def _filter_screenshots
  methods = _build_method_chain

  methods.inject(Screenshot) { |obj, method| obj.send(*method) }
    .order("random()")
    .first
end

def _build_method_chain
  session.keys.map do |field|
    case field
    when "platforms", "publishers"
      _build_like_method(field)
    when "minimum_year"
      minimum_date = "01-01-#{session[field]}"
      _build_equality_method(">=", "original_release_date", minimum_date)
    when "maximum_year"
      maximum_date = "12-31-#{session[field]}"
      _build_equality_method("<=", "original_release_date", maximum_date)
    when "number_of_user_reviews"
      _build_equality_method(">=", field, "1")
    end
  end.compact
end

def _build_like_method(field)
  selected_values = session[field].map{ |value| "%\"#{value}\"%" }
  query = (["#{field} LIKE ?"] * selected_values.count).join(" OR ")
  [:where, query, *selected_values]
end

def _build_equality_method(operator, field, value)
  query = "#{field} #{operator} ?"
  [:where, query, value]
end


_connect_to_database
