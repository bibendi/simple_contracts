# frozen_string_literal: true

require 'json'
require 'logger'

module SimpleContracts
  class Statistics
    TEMPLATE = "[contracts-match] %<payload>s;"

    def initialize(contract_name, logger: nil)
      @contract_name = contract_name
      @logger = logger
    end

    def log(rule, meta, error = nil)
      logger.debug(log_data(rule: rule, meta: meta, error: error))
    end

    private

    def logger
      @logger ||= Logger.new(STDOUT)
    end

    def log_data(**kwargs)
      TEMPLATE % {payload: payload(**kwargs)}
    end

    def payload(rule:, meta: nil, error: nil)
      JSON.dump({
        time: Time.now, contract_name: @contract_name, rule: rule, meta: meta, error: error
      }.compact)
    end
  end
end
