# frozen_string_literal: true

require 'simple_contracts'

class TwitterSearchContract < SimpleContracts::Base
  private

  def twitter_response
    @output
  end

  # Guarantees

  def guarantee_response_structure
    @meta[:response_type] = twitter_response.class.to_s
    return unless twitter_response.respond_to?(:to_hash)

    twitter_response_hash = twitter_response.to_hash
    @tweets = response_tweets(twitter_response_hash)

    @tweets &&
      tweets_count_without_user_id(twitter_response_hash, @tweets).zero?
  end

  # Expectations

  def expect_empty_search
    @tweets.empty?
  end

  def expect_non_empty_search
    users_without_name(@tweets).empty? &&
      users_without_followers_data(@tweets).empty?
  end

  # Helpers

  def response_tweets(response_hash)
    response_hash[:statuses].select { |s| s.dig(:user, :id) }
  end

  def tweets_count_without_user_id(response_hash, tweets)
    @meta[:tweets_count_without_user_id] =
      response_hash[:statuses].count - tweets.count
  end

  def users_without_name(tweets)
    tweets.select { |s| s.dig(:user, :screen_name).nil? }.tap do |statuses|
      @meta[:user_ids_without_screen_name] = statuses.map { |s| s.dig(:user, :id) }
    end
  end

  def users_without_followers_data(tweets)
    tweets.select { |s| s.dig(:user, :followers_count).nil? }.tap do |statuses|
      @meta[:user_ids_without_followers_count] = statuses.map { |s| s.dig(:user, :id) }
    end
  end
end
