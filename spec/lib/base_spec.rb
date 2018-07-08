RSpec.describe SimpleContracts::Base do
  let(:contract) { described_class.new }

  context "when has no defined any guarantees or expectations methods" do
    it "calls with error" do
      expect { contract.call { true } }.to raise_error(SimpleContracts::ExpectationsError)
    end
  end

  context "when has some guarantees and expectations" do
    let(:contract) do
      Class.new(SimpleContracts::Base) do
        private

        def expect_foo
          !!@input[:kwargs][:foo]
        end

        def expect_bar
          !!@input[:kwargs][:bar]
        end

        def guarantee_baz
          !!@input[:kwargs][:baz]
        end

        def guarantee_quz
          !!@input[:kwargs][:quz]
        end
      end
    end

    let(:contract_kwargs) { Hash.new }
    let(:contract_block) { -> { true } }
    let(:call_contract) { contract.call(**contract_kwargs, &contract_block) }

    describe "check expectations" do
      before { contract_kwargs.merge!(baz: true, quz: true) }

      context "when all expectations are false" do
        before { contract_kwargs.merge!(foo: false, bar: false) }

        it { expect { call_contract }.to raise_error(SimpleContracts::ExpectationsError) }
      end

      context "when all expectations are true" do
        before { contract_kwargs.merge!(foo: true, bar: true) }

        it { expect { call_contract }.to_not raise_error }
      end

      context "when only one expectation is true" do
        before { contract_kwargs.merge!(foo: false, bar: true) }

        it { expect { call_contract }.to_not raise_error }
      end
    end

    context "check guarantees" do
      before { contract_kwargs.merge!(foo: true, bar: true) }

      context "when all guarantees are false" do
        before { contract_kwargs.merge!(baz: false, quz: false) }

        it { expect { call_contract }.to raise_error(SimpleContracts::GuaranteesError) }
      end

      context "when all guarantees are true" do
        before { contract_kwargs.merge!(baz: true, quz: true) }

        it { expect { call_contract }.to_not raise_error }
      end

      context "when only one guarantee is true" do
        before { contract_kwargs.merge!(baz: false, quz: true) }

        it { expect { call_contract }.to raise_error(SimpleContracts::GuaranteesError) }
      end
    end
  end
end
