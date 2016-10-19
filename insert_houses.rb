require './scrap_item'
require 'active_record'
require 'pry'

ActiveRecord::Base.establish_connection(
  :adapter => "mysql2",
  :host => "localhost",
  :database => "db/development.sql"
)

class House < ActiveRecord::Base
  validates :price, :description, :user_id, presence: true
  validates :latitude, numericality: { greater_than_or_equal_to: 0 }, presence: true
  validates :longitude, numericality: { less_than_or_equal_to: 0 }, presence: true
end

f = File.open("./report.txt", "r")
f.each_line { |line|
  begin
    url = "http://www.vivanuncios.com.mx#{JSON.parse(line)['link']}"
    scrap = Scrap.new(url)
    house = House.new(scrap.to_hash)
    house.save
  rescue NoMethodError => exc
    p url
  rescue OpenURI::HTTPError => exc
    p url
  end
}
