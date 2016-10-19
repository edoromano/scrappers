require 'json'
require 'open-uri'
require 'nokogiri'
require 'pry'

File.open('./report.txt', 'w') do |file|
  (2..507).each do |page|
    html =  open("http://www.vivanuncios.com.mx/s-inmuebles/nuevo-leon/page-#{page}/v1c30l1018p2").read
    full_page = Nokogiri::HTML(html)
    full_page.xpath('//div[contains(@class, "results list-view ")]/div[contains(@class, "view")]/ul/li').each do |li|
      li_element = Nokogiri::HTML(li.to_html)
      details = li_element.xpath('//div[contains(@class, "container")]/div[contains(@class, "title")]/a').first
      title = details.text
      link = details.attributes['href'].value
      file.write({:title => title, :link => link}.to_json)
      file.write("\n")
    end
  end
end
