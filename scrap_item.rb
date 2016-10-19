require 'json'
require 'pry'
require 'nokogiri'
require 'open-uri'

class Scrap
  attr_accessor :title, :price, :description, :address, :latitude, :longitude, :rooms, :bathrooms, :type, :date_published, :city, :area
  attr_reader :browser

  def initialize(url)
    html =  open(url).read
    @browser = Nokogiri::HTML(html)
    get_title
    get_price
    get_details
    get_location
  end

  def get_title
    @title = @browser.search("span.myAdTitle").text
  end

  def get_price
    @price = @browser.search("div.vip-title>div.price>span.value>span.amount").text
  end

  def get_details
    li_array = @browser.search("div.vip-header-and-details>div.vip-details>ul.selMenu>li")
    li_array.each do |li|
      li = Nokogiri::HTML(li.to_html)
      name = li.xpath("//span[@class='name']").text.strip
      value = li.xpath("//span[@class='value']").text.strip
      case name
      when "Activo desde"
        @date_published = value
      when "Ubicación"
        @city = value
      when "Tipo"
        @type = value
      when "Recámaras"
        @rooms = value
      when "Baños"
        @bathrooms = value
      when "Superficie"
        @area = value
      end
    end
  end

  def get_location
    coordinates = Nokogiri::HTML(@browser.search('div.map>div.wrapper').to_html).at_xpath('//span').attributes['data-uri'].value.split("q=").last.split(",")
    @latitude = coordinates.first
    @longitude = coordinates.last
  end

  def print
    STDOUT.write(JSON.pretty_generate(to_hash))
  end

  def to_hash
    {
      :user_id=>1,
      :price=>@price,
      :description=>@title,
      :latitude=>@latitude,
      :longitude=>@longitude
    }
  end
end
