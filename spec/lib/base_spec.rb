RSpec.describe SimpleContracts::Base do
  let(:contract) { described_class.new }

  context "when has no defined any guarantees or expectations methods" do
    it "calls with error" do
      expect { contract.call { true } }.to_not raise_error
    end
  end

  let(:contract_kwargs) { Hash.new }
  let(:call_contract) { contract.call(logger: nil, **contract_kwargs) { true } }

  context "when has basic guarantees" do
    let(:contract) do
      Class.new(SimpleContracts::Base) do
        private

        def guarantee_foo
          !!@input[:kwargs][:foo]
        end

        def guarantee_bar
          !!@input[:kwargs][:bar]
        end
      end
    end

    context "when all guarantees are false" do
      before { contract_kwargs.merge!(foo: false, bar: false) }
      it { expect { call_contract }.to raise_error(SimpleContracts::GuaranteesError) }
    end

    context "when all guarantees are true" do
      before { contract_kwargs.merge!(foo: true, bar: true) }
      it { expect { call_contract }.to_not raise_error }
    end

    context "when only one guarantee is true" do
      before { contract_kwargs.merge!(foo: false, bar: true) }
      it { expect { call_contract }.to raise_error(SimpleContracts::GuaranteesError) }
    end
  end

  context "when has async guarantees" do
    let(:contract) do
      Class.new(SimpleContracts::Base) do
        private

        def guarantee_foo
          !!@input[:kwargs][:foo]
        end

        def guarantee_bar
          !!@input[:kwargs][:bar]
        end

        def guarantee_baz_async
          !!@input[:kwargs][:baz]
        end

        def guarantee_quz_async
          !!@input[:kwargs][:quz]
        end
      end
    end

    context "when all guarantees are false" do
      before { contract_kwargs.merge!(foo: false, bar: false, baz: false, quz: false) }
      it { expect { call_contract }.to raise_error(SimpleContracts::GuaranteesError) }
    end

    context "when all guarantees are true" do
      before { contract_kwargs.merge!(foo: true, bar: true, baz: true, quz: true) }
      it { expect { call_contract }.to_not raise_error }
    end

    context "when only one basic guarantee is true" do
      before { contract_kwargs.merge!(foo: false, bar: true, baz: false, quz: false) }
      it { expect { call_contract }.to raise_error(SimpleContracts::GuaranteesError) }
    end

    context "when only one async guarantee is true" do
      before { contract_kwargs.merge!(foo: false, bar: false, baz: true, quz: false) }
      it { expect { call_contract }.to raise_error(SimpleContracts::GuaranteesError) }
    end
  end

  context "when has basic expectations" do
    let(:contract) do
      Class.new(SimpleContracts::Base) do
        private

        def expect_foo
          !!@input[:kwargs][:foo]
        end

        def expect_bar
          !!@input[:kwargs][:bar]
        end
      end
    end

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

  context "when has async expectations" do
    let(:contract) do
      Class.new(SimpleContracts::Base) do
        private

        def expect_foo
          !!@input[:kwargs][:foo]
        end

        def expect_bar
          !!@input[:kwargs][:bar]
        end

        def expect_baz_async
          !!@input[:kwargs][:baz]
        end

        def expect_quz_async
          !!@input[:kwargs][:quz]
        end
      end
    end

    context "when all expectations are false" do
      before { contract_kwargs.merge!(foo: false, bar: false, baz: false, quz: false) }
      it { expect { call_contract }.to raise_error(SimpleContracts::ExpectationsError) }
    end

    context "when all expectations are true" do
      before { contract_kwargs.merge!(foo: true, bar: true, baz: true, quz: true) }
      it { expect { call_contract }.to_not raise_error }
    end

    context "when only one basic expectation is true" do
      before { contract_kwargs.merge!(foo: false, bar: true, baz: false, quz: false) }
      it { expect { call_contract }.to_not raise_error }
    end

    context "when only one async expectation is true" do
      before { contract_kwargs.merge!(foo: false, bar: false, baz: false, quz: true) }
      it { expect { call_contract }.to_not raise_error }
    end
  end
end
