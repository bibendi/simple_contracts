# frozen_string_literal: true

require 'io/console'
require 'twitter'
require_relative 'twitter_search_contract'

class TwitterSearch
  DEFAULT_TIMEOUTS = {connect: 2, read: 2}.freeze

  def initialize(credentials, timeouts = nil)
    @credentials = credentials
    @timeouts = timeouts || DEFAULT_TIMEOUTS
  end

  def call(search_query)
    @search_query = search_query
    TwitterSearchContract.call(search_query) do
      @response = client.search(search_query)
    end
  end

  def print
    return unless @response

    users = {}
    @response.to_h[:statuses].each do |status|
      users[status.dig(:user, :screen_name)] = status.dig(:user, :followers_count)
    end

    if users.empty?
      puts "Nothing found in last week Tweets for: `#{@search_query}`. Sorry!"
    else
      print_users(users)
    end
  end

  def print_users(users)
    puts "Interest stats about `#{@search_query}`:"
    puts "Engagement (number of users affected) ~ #{users.values.sum} users"
    puts "Top user stats: "
    users.
      sort_by { |_, v| -v }.
      take(10).
      each { |username, followers| puts " - #{username} has #{followers} followers" }
  end

  def client
    @client ||= ::Twitter::REST::Client.new(
      @credentials.merge(timeouts: @timeouts)
    )
  end
end
