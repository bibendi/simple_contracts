RSpec.describe SimpleContracts::Statistics do
  let(:stats) { described_class.new('contract', logger: logger) }
  let(:logger) { spy("logger") }

  before { Timecop.freeze(Time.utc(1990)) }
  after { Timecop.return }

  describe '#log' do
    it "logs a meta" do
      stats.log('rule', "meta")
      expected_data = '[contracts-match] {"time":"1990-01-01 00:00:00 UTC","contract_name":"contract",' \
                      '"rule":"rule","meta":"meta"};'
      expect(logger).to have_received(:debug).with(expected_data)
    end

    it "logs a meta with error" do
      stats.log('rule', "meta", "error")
      expected_data = '[contracts-match] {"time":"1990-01-01 00:00:00 UTC","contract_name":"contract",' \
                      '"rule":"rule","meta":"meta","error":"error"};'
      expect(logger).to have_received(:debug).with(expected_data)
    end
  end
end
