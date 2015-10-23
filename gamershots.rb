require 'sinatra'
require 'pg'
require 'yaml'
require 'debugger'

connection = PG::Connection.open(:dbname => 'gamershots')
platforms = ""
publishers = ""
minimum_year = ""
maximum_year = ""

get '/' do
  erb :index
end

post '/play' do
  unless params.empty?
    platforms = params["platforms"]
    publishers = params["publishers"]
    minimum_year = params["minimumYear"]
    maximum_year = params["maximumYear"]
  end

  response = connection.exec(<<-SQL)
SELECT 
  name, max(image_url) AS image_url 
FROM 
  screenshots 
WHERE
  publishers LIKE ANY (VALUES#{publishers.map { |value| "('%#{value}%')" }.join(", ")}) 
AND
  platforms LIKE ANY (VALUES#{platforms.map { |value| "('%#{value}%')" }.join(", ")}) 
AND
  original_release_date >= '01-01-#{minimum_year}' 
AND 
  original_release_date <= '12-31-#{maximum_year}' 
GROUP BY 
  name;
  SQL
  games = response.map { |game| game }
  @game = games.shuffle!.pop

  erb :play
end

get '/filter' do
  response = connection.exec("SELECT platforms FROM (SELECT COUNT(*) AS count, platforms FROM screenshots GROUP BY platforms) x WHERE count > 500;") 
  all_platforms = []
  response.each do |result|
    platforms = YAML::load(result["platforms"])
    all_platforms += platforms if platforms
  end
  @all_platforms = all_platforms.sort.uniq

  response = connection.exec("SELECT publishers FROM (SELECT COUNT(*) AS count, publishers FROM screenshots GROUP BY publishers) x WHERE count > 500;") 
  all_publishers = []
  response.each do |result|
    publishers = YAML::load(result["publishers"])
    all_publishers += publishers if publishers
  end
  @all_publishers = all_publishers.sort.uniq

  response = connection.exec("SELECT DISTINCT(EXTRACT(YEAR FROM original_release_date)) AS original_release_year FROM screenshots ORDER BY original_release_year;")
  @years = response.values.flatten

  erb :filter
end
