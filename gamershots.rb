require 'rubygems'
require 'sinatra'
require 'pg'
require 'yaml'

db = URI.parse(ENV['DATABASE_URL'])
connection = PG::Connection.open(
  :host => db.host,
  :user => db.user,
  :password => db.password,
  :dbname => db.path[1..-1]
)

platforms = ""
publishers = ""
minimum_year = ""
maximum_year = ""
user_reviews = ""
platforms_query_string = ""
publishers_query_string = ""
games = []

get '/' do
  erb :index
end

post '/play' do
  unless params.empty?
    platforms = params["platforms"]
    publishers = params["publishers"]
    minimum_year = params["minimumYear"]
    maximum_year = params["maximumYear"]
    user_reviews = params["userReviews"]

    minimum_year = "1935" if minimum_year == "---"
    maximum_year = "2015" if maximum_year == "---"
    platforms_query_string = "AND platforms LIKE ANY (VALUES#{platforms.map { |value| "('%#{value.gsub('_', ' ')}%')" }.join(", ")})" if platforms
    publishers_query_string = "AND publishers LIKE ANY (VALUES#{publishers.map { |value| "('%#{value.gsub('_', ' ')}%')" }.join(", ")})" if publishers
    user_review_query_string = "AND number_of_user_reviews != 0" if user_reviews
  end

  response = connection.exec(<<-SQL) if games.empty?
SELECT 
  *
FROM 
  screenshots 
WHERE
  original_release_date >= '01-01-#{minimum_year}' 
AND 
  original_release_date <= '12-31-#{maximum_year}' 
#{platforms_query_string}
#{publishers_query_string}
#{user_review_query_string}
ORDER BY
  random()
LIMIT
  1000
  SQL

  games = response.map { |game| game } if games.empty?
  @game = games.shuffle!.pop

  erb :play
end

get '/filter' do
  games = []

  response = connection.exec(<<-SQL)
SELECT
  platforms
FROM 
  (SELECT
    COUNT(*) AS count, platforms 
  FROM
    screenshots 
  GROUP BY 
    platforms) x
WHERE
  count > 1000; 
  SQL

  all_platforms = []
  response.each do |result|
    platforms = YAML::load(result["platforms"])
    all_platforms += platforms if platforms
  end
  @all_platforms = all_platforms.sort.uniq

  response = connection.exec(<<-SQL)
SELECT
  publishers
FROM
  (SELECT
    COUNT(*) AS count, publishers
  FROM
    screenshots
  GROUP BY
    publishers) x 
WHERE
  count > 1000;
  SQL

  all_publishers = []
  response.each do |result|
    publishers = YAML::load(result["publishers"])
    all_publishers += publishers if publishers
  end
  @all_publishers = all_publishers.sort.uniq

  response = connection.exec(<<-SQL)
SELECT
  DISTINCT(EXTRACT(YEAR FROM original_release_date)) AS original_release_year
FROM
  screenshots
ORDER BY
  original_release_year;
  SQL

  @years = response.values.flatten

  erb :filter
end
