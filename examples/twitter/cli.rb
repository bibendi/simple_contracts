# frozen_string_literal: true

require_relative 'twitter_search'

class Cli
  def ask_credentials
    return @credentials if defined?(@credentials)

    puts "Enter Twitter access string (login, access_token, access_token_secret, " \
         "consumer_key, consumer_secret) joined by `::`"
    access_string = STDIN.noecho(&:gets).chomp
    access_data = access_string.split("::")
    keys = %i(login access_token access_token_secret consumer_key consumer_secret)
    @credentials = Hash[keys.zip(access_data)]
  end

  def search(search_query, credentials = ask_credentials)
    twitter_search = TwitterSearch.new(credentials)
    twitter_search.call(search_query)
    twitter_search.print
  end
end
