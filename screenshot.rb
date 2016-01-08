class Screenshot < ActiveRecord::Base
  self.primary_key = 'id'

  def sonic
    name.downcase.include?("sonic")
  end
end
