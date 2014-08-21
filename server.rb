require 'sinatra'
require 'csv'
require 'pry'
require 'uri'

def remove_http(array)
  array.each do |row|
    row[:url] = row[:url].gsub(/(http\:\/\/)|(https\:\/\/)/, "")
  end
  array
end

def read_articles
  article_data = []
  CSV.foreach("articles.csv", headers: true, header_converters: :symbol) do |row|
    article_data << row.to_hash
  end
  article_data
end

def random_key
  char = ("a".."z").to_a + ("A".."Z").to_a + ("0".."9").to_a
  key = ""
  10.times { key << char[rand(char.size)]}
  key
end

def bad_title_or_url(title_string,url_string)
  out = false
  out = (url_string != /((([A-Za-z]{3,9}:(?:\/\/)?)(?:[\-;:&=\+\$,\w]+@)?[A-Za-z0-9\.\-]+|(?:www\.|[\-;:&=\+\$,\w]+@)[A-Za-z0-9\.\-]+)((?:\/[\+~%\/\.\w\-_]*)?\??(?:[\-\+=&;%@\.\w_]*)#?(?:[\.\!\/\\\w]*))?)/.match(url_string).to_s) || (title_string == "") || (url_string == "")
  return out
end

def check_if_url_already_exists(string)

  just_urls = []
  CSV.foreach("articles.csv", headers: true, header_converters: :symbol) do |row|
    just_urls << row[:url]
  end

  if just_urls.include?(string)
    return true
  else
    return false
  end

end

get '/' do

  @article_data = read_articles
  @article_data = remove_http(@article_data)

  erb :index
end

get '/submit' do

  if $error_global == 1
    @error_message = "You have an error. Try re-entering the details"
  elsif $error_global == 2
    @error_message = "Your URL has already been submitted. Try Another."
  else
    @error_message = ""
  end

  erb :submit
end

post '/submit' do

  title = params["title"]
  url = params["url"]
  text = params["text"]
  datetime = Time.now
  id = random_key

  if bad_title_or_url(title,url)
    $error_global = 1
    redirect '/submit'

  elsif check_if_url_already_exists(url) == true
    $error_global = 2
    redirect '/submit'
  else
    $error_global = 0
    CSV.open("articles.csv", "a", headers: true) do |row|
      row << [id, datetime, title, url, text]
    end
    redirect '/'
  end

end
