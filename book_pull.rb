require 'open-uri'
require 'json'

# This class is a wrapper around the Google Books api.
# It will attempt to read a public api key from 'api_key' file.
# Use:
#   BookPull.search('ruby on rails', 100)
#   - this will return an array of 100 `items`. Refer to api documentation for
#   more info
class BookPull
  # Reads api key from a file and prepares the book api uri
  def initialize
    url = "https://www.googleapis.com/books/v1/volumes"
    key = File.open('api_key') { |f| f.read.strip }
    @uri = "#{url}?key=#{key}"
  end

  # Submits search queries to get `count` results.
  # Google Books api by default limits results per query to 40, this method
  # allows you to combine more requests in a single method call.
  def self.search(query, count = 10)
    max_results = 40
    start_index = 0
    items = []

    while start_index < count
      # Make sure we're not requesting too many results.
      # E.g. When start_index == 160 and count == 180, change max_results to 20
      max_results = count - start_index if count - start_index < max_results

      results = self.new.search_from_upto(query, start_index, max_results)
      items += results['items']

      start_index += max_results
    end

    items
  end

  # Submits search queries to get `count` results.
  # Then extracts title, image urls and authors info.
  # Returns a hash that can be used in Rails to `create`.
  def self.extract_book_info(query, count = 200)
    per_page = 40
    start_from = 0

    items = self.search(query, count)
    items.map do |item|
      item = item['volumeInfo']
      puts item
      {
        title:   item['title'],
        authors: item['authors'],
        img_url: extract_image(item)
      }
    end
  end

  # Extracts image url from result item if one exists, and changes it's size.
  def self.extract_image(item)
    return nil unless item.has_key? 'imageLinks'

    url = item['imageLinks'].values.last
    url.gsub(/zoom=\d+/, 'zoom=4')
  end

  # Submits a single request.
  def request(params = {})
    uri = @uri
    params.each { |key, value| uri += "&#{key}=#{value}" }
    result = open(uri) { |f| parse(f.read) }
  end

  # Submits a single search request.
  def search(query, params = {})
    params[:q] = query
    request(params)
  end

  # Submits a single search request.
  # Args:
  #   offset - startIndex
  #   limit  - maxResults
  def search_from_upto(query, offset, limit, params = {})
    params['startIndex'] = offset
    params['maxResults'] = limit
    search(query, params)
  end

  def parse(result)
    JSON.parse(result)
  end
end

