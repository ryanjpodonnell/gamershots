class Player
  attr_reader :player_number
  attr_accessor :score

  def initialize(player_number)
    @player_number = player_number
    @score = 0
  end
end
