require 'json'
require 'pry'
require 'nokogiri'
require 'open-uri'
require 'active_record'

ActiveRecord::Base.establish_connection(
  :adapter => "mysql2",
  :host => "localhost",
  :database => "db/development.sql"
)

class Scrap
  attr_reader :browser

  def initialize(url)
    html =  open(url).read
    @browser = Nokogiri::HTML(html)
    get_house_details
  end

  def get_house_details
    @browser.search("td.cuerporesultado>table").slice(1..-2).each do |table|
      begin
        price = table.search("td.tituloresultchico>table>tr>td").first.children.first.text.gsub(/[,|$ ]/, "").to_i.to_s
        neighborhood = table.search("td.tituloresultchico>table>tr").first.children.children.last.text.strip
        city = table.search("td.tituloresultchico>table>tr").first.children.children[3].text.strip
        floors = table.search("table.ar12gris/tr[2]/td/table/tr[1]/td[1]").text.split(" planta").first
        area = table.search("table.ar12gris/tr[2]/td/table/tr[1]/td[2]").text.split("m²").first
        rooms =  table.search("table.ar12gris/tr[2]/td/table/tr[2]/td[1]").text.split(" rec").first
        bathrooms = table.search("table.ar12gris/tr[2]/td/table/tr[3]/td[1]").text.split.first
        latitude = table.search("table.ar12gris/tr[2]/td/table/tr[4]/td[3]/a[class='tool']").first.attributes['onclick'].value.split(",")[3].gsub(/[']/,"")
        longitude = table.search("table.ar12gris/tr[2]/td/table/tr[4]/td[3]/a[class='tool']").first.attributes['onclick'].value.split(",")[4].gsub(/[']/,"")
        house = House.new(:price => price,
                          :user_id => 1,
                          :neighborhood => neighborhood,
                          :city => city,
                          :floors => floors,
                          :area => area,
                          :rooms =>rooms,
                          :bathrooms => bathrooms,
                          :latitude => latitude,
                          :longitude => longitude)
        house.save
      rescue Exception => exc
        p "exc #{exc.message}"
      end
    end
  end
end

class House < ActiveRecord::Base
  validates :price, :user_id, presence: true
  validates :latitude, numericality: { greater_than_or_equal_to: 0 }, presence: true
  validates :longitude, numericality: { less_than_or_equal_to: 0 }, presence: true
end

(1..130).each do |page|
#  Scrap.new("http://www.avisosdeocasion.com/Resultados-Inmuebles.aspx?n=venta-casas-nuevo-leon&PlazaBusqueda=2&Plaza=2&pagina=#{page}&idinmueble=3")
  Scrap.new("http://www.avisosdeocasion.com/reforma/venta/casas/casas.aspx?ntext=venta-casas-casas-Distrito-Federal&PlazaBusqueda=1&Plaza=1&pagina=#{page}")
end
