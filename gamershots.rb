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

configure do
  set :params, nil
end

get '/' do
  erb :index
end

post '/play' do
  settings.params = params.empty? ? settings.params : params
  @screenshot = _filter_screenshots
  return erb :index if @screenshot.nil?

  erb :play
end

get '/filter' do
  settings.params = nil

  erb :filter
end

def _filter_screenshots
  _delete_unused_year_params
  methods = _build_method_chain

  methods.inject(Screenshot) { |obj, method| obj.send(*method) }
    .order("random()")
    .first
end

def _delete_unused_year_params
  ["minimum_year", "maximum_year"].each do |field|
    settings.params.delete(field) if settings.params[field] == "---"
  end
end

def _build_method_chain
  settings.params.keys.map do |field|
    case field
    when "platforms", "publishers"
      _build_like_method(field)
    when "minimum_year"
      minimum_date = "01-01-#{settings.params[field]}"
      _build_equality_method(">=", "original_release_date", minimum_date)
    when "maximum_year"
      maximum_date = "12-31-#{settings.params[field]}"
      _build_equality_method("<=", "original_release_date", maximum_date)
    when "number_of_user_reviews"
      _build_equality_method(">=", field, "1")
    end
  end
end

def _build_like_method(field)
  selected_values = settings.params[field].map{ |value| "%#{value}%" }
  query = (["#{field} LIKE ?"] * selected_values.count).join(" OR ")
  [:where, query, *selected_values]
end

def _build_equality_method(operator, field, value)
  query = "#{field} #{operator} ?"
  [:where, query, value]
end
