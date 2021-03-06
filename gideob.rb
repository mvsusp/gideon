require 'rubygems'
require 'sinatra'
require 'haml'
require 'mongo'
require 'uri'
require 'json'
require 'ruby-debug/debugger'

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

post '/submit_page' do
  d = db['inner_pages'].update({ :_id => BSON::ObjectId(params[:id])},{ "$set" => {:results => params[:results]}})
  'resultado armazenado' 
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
    end
    inner_pages.last[:page] += line
  end
  inner_pages
end

REDUCE_FUNCTION = "
  var sum = 0;
  data.replace(',', '');
  var words = data.split(/ /).sort();
  result = {};
  for (var i = 0; i < words.length; i++) {
    var word = words[i];
    if (result[word]) {
      result[word] += 1;
    } else {
      result[word] = 1;
    }
  }
  return result;
"

get '/next_page.json' do
  content_type :json

  page_name = 'biblia_online' 
  web_page = db['web_pages'].find_one({:name => page_name})

  next_page = get_next_page(web_page)
  a = db['inner_pages'].insert(next_page)

  {:func => REDUCE_FUNCTION, :inner_page => next_page}.to_json
end

def get_next_page(web_page)
  crawled_pages = db['inner_pages'].find({:page_name => web_page['name'], :results => { :$exists => false }}) 
  if crawled_pages.count == 0
    web_page['pages'][0]
  else
    left_pages = web_page['pages'] - crawled_pages.map{|page| page['slug']}
    if left_pages.size == 0
      final_reduce(crawled_pages)  
    else
      left_pages[0]
    end
  end
end
