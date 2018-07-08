# frozen_string_literal: true

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

      private

      def methods_with_prefix(prefix)
        private_instance_methods.
          select { |method_name| method_name.to_s.start_with?(prefix) }
      end
    end

    def call(*args, **kwargs)
      @input = {args: args, kwargs: kwargs}
      @meta = {checked: []}
      @output = yield

      match_guarantees!
      match_expectations!
    rescue GuaranteesError, ExpectationsError
      raise
    rescue StandardError => error
      # TODO: use logger here
      puts "Unexpected error #{error}, meta: #{@meta.inspect}"
      raise
    end

    alias match! call

    private

    def match_guarantees!
      return if self.class.guarantees_methods.all? do |method_name|
        @meta[:checked] << method_name
        send(method_name)
      end

      raise GuaranteesError, @meta
    end

    def match_expectations!
      return if self.class.expectations_methods.any? do |method_name|
        @meta[:checked] << method_name
        send(method_name)
      end

      raise ExpectationsError, @meta
    end
  end
end
