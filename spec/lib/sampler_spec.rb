RSpec.describe SimpleContracts::Sampler do
  let(:sampler) { described_class.new(contract) }

  before { FileUtils.rm_rf(File.join('/tmp', 'contracts')) }

  describe '#sample!' do
    let(:contract) { double('contract', contract_name: 'contract_name', serialize: 'contract-content') }

    before { Timecop.freeze(Time.utc(1990, 1, 1, 10, 0, 1)) }
    after { Timecop.return }

    it "serializes context to file" do
      sample_path = sampler.sample!(:rule_name)
      expect(sample_path).to eq '/tmp/contracts/contract_name/rule_name/175330.dump'
      expect(File.exist?(sample_path)).to be true
      expect(File.read(sample_path)).to eq 'contract-content'
    end

    it "serializes context to file only once a period" do
      sampler.sample!(:rule_name)
      Timecop.travel(Time.utc(1990, 1, 1, 10, 0, 1))
      expect(sampler.sample!(:rule_name)).to be nil
    end
  end
end
