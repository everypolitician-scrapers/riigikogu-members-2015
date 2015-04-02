
# Fetch member information from riigikogu.ee

require 'json'
require 'scraperwiki'
require 'nokogiri'
require 'open-uri'
# require 'open-uri/cached'
# OpenURI::Cache.cache_path = '/tmp/open-uri'

def noko_for(url)
  Nokogiri::HTML(open(url).read)
end

def member_urls
  index = 'http://www.riigikogu.ee/index.php' 
  page = index + '?id=31555&op2=print'
  noko = noko_for(page)
  noko.css('.DDW_Body #DDW_EMSI a').map { |a| index + a['href'] + '&op2=print' }
end

def epost(txt)
  txt.gsub(' dot ','.').gsub(' at ','@')
end

def member_info(url)
  noko = noko_for(url)
  data = { 
    name: noko.css("div.category").text.split(':').last.strip,
    img: 'http://www.riigikogu.ee' + noko.css("img.Picture").attr('src').text,
    faction: noko.xpath("//div[contains(@class, 'Label') and normalize-space(text()) = 'Fraktsioon:']/following-sibling::div/a[1]").text.strip,
    area: noko.xpath("//div[contains(@class, 'Label') and normalize-space(text()) = 'Valimisringkond:']/following-sibling::div").text.strip,
    email: epost(noko.xpath("//div[contains(@class, 'Label') and normalize-space(text()) = 'E-post:']/following-sibling::div/a").text.strip),
  }
  data[:id] = data[:img][/pid=([^&]+)/,1]
  data[:house] = 'Riigikogu XIII'
  return data
end

member_urls.each_with_index do |u, i|
  data = member_info(u)
  puts "Adding #{i+1}. #{data[:name]}: #{data[:faction]}"
  ScraperWiki.save_sqlite([:id], data)
end
