# frozen_string_literal: true

module SimpleContracts
  class Sampler
    PATH_TEMPLATE = "%<contract_name>s/%<rule>s/%<period>i.dump"
    DEFAULT_PERIOD_SIZE = 60 * 60 # every hour

    def initialize(contract, period_size: nil)
      @context = contract
      @contract_name = contract.contract_name
      @period_size = period_size || default_period_size
    end

    def sample!(rule)
      path = sample_path(rule)
      return unless need_sample?(path)
      capture(rule)
      path
    end

    def sample_path(rule, period = current_period)
      File.join(
        root_path,
        PATH_TEMPLATE % {contract_name: @contract_name, rule: rule, period: period}
      )
    end

    # to use in interactive Ruby session
    def read(path = nil, rule: nil, period: nil)
      path ||= sample_path(rule, period)
      raise(ArgumentError, "Sample path should be defined") unless path
      @context.deserialize(File.read(path))
    end

    private

    def need_sample?(path)
      !File.exist?(path)
    end

    def capture(rule)
      FileUtils.mkdir_p(File.dirname(sample_path(rule)))
      File.write(sample_path(rule), @context.serialize)
    end

    def current_period
      Time.now.to_i / (@period_size || 1).to_i
    end

    def default_period_size
      Integer(ENV["CONTRACT_#{@contract_name}_SAMPLE_PERIOD_SIZE"] || DEFAULT_PERIOD_SIZE)
    end

    def root_path
      ENV["CONTRACT_ROOT_PATH"] || File.join("/tmp", "contracts")
    end
  end
end
