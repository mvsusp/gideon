require 'rubygems'
require 'sinatra'
require 'haml'
require 'mongo'
require 'uri'
require 'json'

SINATRA_HOME = "localhost:4567"

def db
  @db ||= Mongo::Connection.new.db("gideon")
end

get '/crawler' do
    haml :index
end

get '/insert_data' do
  haml :insert_data
end

post '/upload' do
  file = params[:file]
  filename = params[:name]
  pages = map_pages(filename, file)
  db['web_pages'].insert({ :name => filename, :pages => pages})
end

def map_pages(filename, file)
  tempfile = file[:tempfile]
  page_size = 500
  offset = 0
  inner_pages = []
  tempfile.each_with_index do |line, index|
    if index == 0 or (index - offset) > page_size
      inner_pages << {:page_name => filename, :slug => index, :url => "inner_page/#{filename}/#{index}", :page => ''}
      offset += page_size if (index - offset) > page_size
      puts 'new page'
    end
    inner_pages.last[:page] += line
  end
  inner_pages
end

get '/next_page.json' do
  content_type :json

  page_name = 'biblia_online' 
  web_page = db['web_pages'].find_one({:name => page_name})

  next_page = get_next_page(web_page)
  a = db['inner_pages'].insert(next_page)

  next_page.to_json
end

def get_next_page(web_page)
  crawled_pages = db['inner_pages'].find({:page_name => web_page['name']}) 
  if crawled_pages.count == 0
    web_page['pages'][0]
  else
    (web_page['pages'] - crawled_pages.map{|page| page['slug']})[0]
  end
end
