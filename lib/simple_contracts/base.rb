# frozen_string_literal: true

require 'celluloid/current'

# Base class for writting contracts.
# the only public method is SimpleContracts::Base#call (or alias SimpleContracts::Base#match!)
#
# The purpose is to validate some action against your expectations.
# There are 2 kind of them:
# - Guarantee - state that SHOULD be recognized for after every the actions
# - Expectation - state that COULD be recognized after the action
#
# The key behavior is:
# - First verify that all Guarantees are met, then
# - Then move to Expectation and verify that at least one of them met.
# - If any of those checks fail - we should recieve detailed exception - why.
#
# There are 2 kind of exceptions:
# - GuaranteeError - happens if one of the Guarantees failes
# - ExpectationsError - happens if none of Expextations were meet.
#
# Both of them raise with the @meta object, which contains extra debugging info.
module SimpleContracts
  class GuaranteesError < StandardError; end
  class ExpectationsError < StandardError; end

  class Base
    include ::Celluloid

    class << self
      def call(*args, **kwargs)
        new.call(*args, **kwargs) { yield }
      end

      def guarantees_methods
        @guarantees ||= methods_with_prefix("guarantee_")
      end

      def expectations_methods
        @expectations ||= methods_with_prefix("expect_")
      end

      def parallel_check?(method_name)
        method_name.end_with?("_async")
      end

      private

      def methods_with_prefix(prefix)
        private_instance_methods.
          each_with_object([]) do |method_name, memo|
            method_name = method_name.to_s
            next unless method_name.start_with?(prefix)
            memo << method_name
          end
      end
    end

    def call(*args, logger: STDOUT, **kwargs)
      @input = {args: args, kwargs: kwargs}
      @meta = {checked: []}
      @output = yield

      match_guarantees!
      match_expectations!
    rescue GuaranteesError, ExpectationsError
      raise
    rescue StandardError => error
      logger.error("Unexpected error #{error}, meta: #{@meta.inspect}") if logger
      raise
    end

    alias match! call

    private

    def match_guarantees!
      result = true
      futures = []
      methods = self.class.guarantees_methods
      return if methods.empty?

      methods.each do |method_name|
        @meta[:checked] << method_name

        if self.class.parallel_check?(method_name)
          futures << future.send(method_name)
        else
          result &&= send(method_name)
        end

        break unless result
      end

      return if result && (futures.empty? || futures.all?(&:value))

      abort GuaranteesError.new(@meta)
    end

    def match_expectations!
      result = false
      futures = []
      methods = self.class.expectations_methods
      return if methods.empty?

      methods.each do |method_name|
        @meta[:checked] << method_name

        if self.class.parallel_check?(method_name)
          futures << future.send(method_name)
        else
          result ||= send(method_name)
        end

        break if result
      end

      return if result || futures.any?(&:value)

      abort ExpectationsError.new(@meta)
    end
  end
end
