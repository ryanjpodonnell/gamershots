require 'httparty'
require 'csv'

class Scraper
  def initialize
    @api_key = ""
    @offset = 47110
    @database = CSV.open("screenshots.csv", "a", :headers => true)
  end

  def run
    while games_hash = generate_games_hash
      until games_hash.empty?
        scrape_games(games_hash)
      end
    end
  end

  def generate_games_hash
    sleep 2.5
    games_response = HTTParty.get("http://www.giantbomb.com/api/games/?api_key=#{@api_key}&format=json&offset=#{@offset}") 
    response_hash = JSON.parse(games_response.body)

    games_hash = {}
    if response_hash["status_code"] == 1
      games_hash = response_hash["results"]
    end
    games_hash
  end

  def scrape_games(games_hash)
    while games_hash.length > 0
      game = games_hash.shift
      @offset += 1
      puts "#{@offset} #{game["name"]}"
      game_id = game["id"]
      game = scrape_game(game_id)
      screenshots = scrape_screenshots(game)
      store_screenshots(screenshots, game) if game["original_release_date"]
    end
  end

  def scrape_game(game_id)
    sleep 2.5
    game_response = HTTParty.get("http://www.giantbomb.com/api/game/#{game_id}/?api_key=#{@api_key}&format=json") 
    response_hash = JSON.parse(game_response.body)

    game_hash = {}
    if response_hash["status_code"] == 1
      game_hash = response_hash["results"]
    end
    game_hash
  end

  def scrape_screenshots(game)
    images = game["images"]

    screenshots = []
    images.each do |image|
      if image["tags"].downcase.include?("screenshot")
        screenshots << image["super_url"]
      end
    end
    screenshots
  end

  def store_screenshots(screenshots, game)
    screenshots.each do |screenshot|
     data_hash = {"id" => "", "image_url" => "", "name" => "", "developers" => "", "genres" => "", "number_of_user_reviews" => "", "original_release_date" => "", "platforms" => "", "publishers" => ""}
     data_hash["id"] = game["id"]
     data_hash["image_url"] = screenshot 
     data_hash["name"] = game["name"]
     data_hash["developers"] = game["developers"].map{|developer| developer["name"]} if game["developers"]
     data_hash["genres"] = game["genres"].map{|genre| genre["name"]} if game["genres"]
     data_hash["number_of_user_reviews"] = game["number_of_user_reviews"]
     data_hash["original_release_date"] = game["original_release_date"]
     data_hash["platforms"] = game["platforms"].map{|platform| platform["name"]} if game["platforms"]
     data_hash["publishers"] = game["publishers"].map{|publisher| publisher["name"]} if game["publishers"]
     @database << data_hash.values
    end
  end
end

scraper = Scraper.new
scraper.run
