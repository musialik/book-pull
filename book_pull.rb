require 'open-uri'
require 'json'

class BookPull
  def initialize
    url = "https://www.googleapis.com/books/v1/volumes"
    key = File.open('api_key') { |f| key = f.read }
    @uri = "#{url}?key=#{key}"
  end

  def self.search(query)
    self.new.search(query)
  end

  def self.extract_book_info(query, count = 200)
    per_page = 40
    start_from = 0

    bookpull = self.new
    book_info = []
    until start_from > count do
      result = bookpull.search(
          query,
          'startIndex' => start_from,
          'maxResults' => per_page
        )
      start_from += per_page
      #book_info += parse_results(result)
    end
  end

  def request(params = {})
    uri = @uri
    params.each { |key, value| uri += "&#{key}=#{value}" }
    open(uri) { |f| parse(f.read) }
  end

  def search(query, params = {})
    params[:q] = query
    request(params)
  end

  def parse(result)
    JSON.parse(result)
  end
end

