# frozen_string_literal: true

require 'concurrent/future'
require 'logger'

require 'simple_contracts/sampler'
require 'simple_contracts/statistics'

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
        new(*args, **kwargs).call { yield }
      end

      def guarantees_methods
        @guarantees_methods ||= methods_with_prefix("guarantee_")
      end

      def expectations_methods
        @expectations_methods ||= methods_with_prefix("expect_")
      end

      private

      def methods_with_prefix(prefix)
        private_instance_methods.
          each_with_object([]) do |method_name, memo|
            method_name = method_name.to_s
            next unless method_name.start_with?(prefix)
            memo << method_name
          end.sort
      end
    end

    def initialize(*args, async: nil, logger: nil, sampler: nil, stats: nil, **kwargs)
      @async = async.nil? ? default_async : !!async
      @sampler = sampler
      @stats = stats
      @logger = logger
      @input = {args: args, kwargs: kwargs}
      @meta = {checked: [], input: @input}
    end

    def call
      return yield unless enabled?
      @output = yield
      @async ? verify_async : verify
      @output
    end

    alias match! call

    def serialize
      Marshal.dump(input: @input, output: @output, meta: @meta)
    end

    def deserialize(state_dump)
      Marshal.load(state_dump)
    end

    def contract_name
      self.class.name
    end

    private

    def default_async
      true
    end

    def concurrent_options
      {}
    end

    def call_matchers
      match_guarantees!
      match_expectations!
    end

    def verify
      call_matchers
    rescue StandardError => error
      observe_errors(Time.now, nil, error)
      raise
    end

    def verify_async
      execute_async { call_matchers }
    end

    def execute_async
      ::Concurrent::Future.
        execute(concurrent_options) { yield }.
        add_observer(self, :observe_errors)
    end

    def observe_errors(_time, _value, reason)
      return unless reason

      rule = rule_from_error(reason)
      error = reason if rule == :unexpected_error

      keep_meta(rule, error)
    rescue StandardError => error
      logger.error(error)
      raise
    end

    def rule_from_error(error)
      case error
      when GuaranteesError
        :guarantee_failure
      when ExpectationsError
        :expectation_failure
      else
        :unexpected_error
      end
    end

    def keep_meta(rule, error = nil)
      sample_path = sampler.sample!(rule)
      meta = sample_path ? @meta.merge(sample_path: sample_path) : @meta
      stats.log(rule, meta, error)
    end

    def sampler
      @sampler ||= ::SimpleContracts::Sampler.new(self)
    end

    def stats
      @stats ||= ::SimpleContracts::Statistics.new(contract_name, logger: logger)
    end

    def logger
      @logger ||= ::Logger.new(STDOUT)
    end

    def enabled?
      ENV["ENABLE_#{self.class.name}"].to_s != 'false'
    end

    def match_guarantees!
      methods = self.class.guarantees_methods
      return if methods.empty?
      return if methods.all? do |method_name|
        @meta[:checked] << method_name
        !!send(method_name)
      end

      raise GuaranteesError, @meta
    end

    def match_expectations!
      methods = self.class.expectations_methods
      return if methods.empty?
      return if methods.any? do |method_name|
        @meta[:checked] << method_name
        next unless !!send(method_name)
        keep_meta(method_name)
        true
      end

      raise ExpectationsError, @meta
    end
  end
end
