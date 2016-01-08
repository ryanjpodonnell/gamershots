require 'pg'
require 'rubygems'
require 'sinatra'
require 'sinatra/activerecord'
require 'sinatra/cookies'
require 'json'
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

enable :sessions

get '/' do
  erb :index
end

post '/play' do
  session.clear if params.present?
  params.each do |key, value|
    next if ["minimum_year", "maximum_year"].include?(key) && value == "---"
    session[key] = value
  end

  @screenshot = _filter_screenshots
  return erb :index if @screenshot.nil?

  erb :play
end

get '/filter' do
  erb :filter
end

get '/richard' do
  content_type :json

  screenshot = Screenshot.order("random()").first

  screenshot.to_json(:methods => :sonic)
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
