require 'rubygems'
require 'sinatra'
require 'haml'
require 'mongo'
require 'uri'
require 'json'
require 'ruby-debug/debugger'

def db
  @db ||= Mongo::Connection.new.db("gideon")
end

get '/crawler' do
    haml :index
end

get '/insert_data' do
  #web_pages_collection = db.collection('web_pages')
  #biblia_online = { :name => 'biblia_online', :href => 'http://www.bibliaonline.com.br/acf/', :pages => ['gn/1','gn/2','gn/3','gn/4','gn/5','gn/6','gn/7','gn/8','gn/9','gn/10','gn/11','gn/12','gn/13','gn/14','gn/15','gn/16','gn/17','gn/18','gn/19','gn/20','gn/21','gn/22','gn/23','gn/24','gn/25','gn/26','gn/27','gn/28','gn/29','gn/30','gn/31','gn/32','gn/33','gn/34','gn/35','gn/36','gn/37','gn/38','gn/39','gn/40','gn/41','gn/42','gn/43','gn/44','gn/45','gn/46','gn/47','gn/48','gn/49','gn/50']}
  #web_pages_collection.insert(biblia_online)
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
    page_is_full? = (index - offset) > page_size
    offset += page_size if page_is_full?
    if index == 0 or page_is_full?
      inner_pages << {:page_name => filename, :slug => index, :url => filename + '/' + index, :page => ''}
    end
    inner_pages.last.page += line
  end
  inner_pages
end

get '/next_page.json' do
  content_type :json

  page_name = 'biblia_online' 
  web_page = db['web_pages'].find_one({:name => page_name})

  next_page = get_next_page(web_page)
  url = URI.join(web_page['href'], next_page).to_s

  new_inner_page = {:page_name => page_name, :slug => next_page, :url => url}
  a = db['inner_pages'].insert(new_inner_page)

  new_inner_page.to_json
end

def get_next_page(web_page)
  crawled_pages = db['inner_pages'].find({:page_name => web_page['name']}) 
  if crawled_pages.count == 0
    web_page['pages'][0]
  else
    (web_page['pages'] - crawled_pages.map{|page| page['slug']})[0]
  end
end
