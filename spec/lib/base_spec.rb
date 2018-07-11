RSpec.describe SimpleContracts::Base do
  let(:contract_kwargs) { Hash.new }
  let(:logger) { spy('logger') }
  let(:stats) { double("stats") }
  let(:call_contract) { contract.(logger: logger, stats: stats, **contract_kwargs) { true } }

  before { FileUtils.rm_rf(File.join('/tmp', 'contracts')) }

  context "when has no defined any guarantees or expectations methods" do
    it "calls with error" do
      expect { described_class.call { true } }.to_not raise_error
    end
  end

  describe "verify guarantees" do
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

    context "when synchronus verification" do
      let(:contract_kwargs) { {async: false} }

      context "when all guarantees are false" do
        it do
          contract_kwargs.merge!(foo: false, bar: false)
          expect(stats).to receive(:log).
            with(:guarantee_failure,
                 {checked: %w(guarantee_bar),
                  input: {args: [], kwargs: {foo: false, bar: false}},
                  sample_path: kind_of(String)},
                 nil)
          expect { call_contract }.to raise_error(SimpleContracts::GuaranteesError)
        end
      end

      context "when all guarantees are true" do
        before { contract_kwargs.merge!(foo: true, bar: true) }
        it { expect { call_contract }.to_not raise_error }
      end

      context "when only one guarantee is true" do
        it do
          contract_kwargs.merge!(foo: false, bar: true)
          expect(stats).to receive(:log).
            with(:guarantee_failure,
                 {checked: %w(guarantee_bar guarantee_foo),
                  input: {args: [], kwargs: {foo: false, bar: true}},
                  sample_path: kind_of(String)},
                 nil)
          expect { call_contract }.to raise_error(SimpleContracts::GuaranteesError)
        end
      end

      context "when unexpected error" do
        let(:contract) do
          Class.new(SimpleContracts::Base) do
            private

            def guarantee_foo
              raise "Boom!"
            end
          end
        end

        it do
          expect(stats).to receive(:log).
            with(:unexpected_error,
                 {checked: %w(guarantee_foo),
                  input: {args: [], kwargs: {}},
                  sample_path: kind_of(String)},
                 kind_of(RuntimeError))
          expect { call_contract }.to raise_error(StandardError)
        end
      end
    end

    context "when asynchronus verification" do
      before do
        allow_any_instance_of(contract).
          to receive(:concurrent_options).
          and_return(executor: :immediate)
      end

      context "when all guarantees are false" do
        it "catches an error" do
          contract_kwargs.merge!(foo: false, bar: false)
          expect(stats).to receive(:log).
            with(:guarantee_failure,
                 {checked: ["guarantee_bar"],
                  input: {args: [], kwargs: {foo: false, bar: false}},
                  sample_path: kind_of(String)},
                 nil)
          call_contract
        end
      end

      context "when all guarantees are true" do
        it "does not catche an error" do
          contract_kwargs.merge!(foo: true, bar: true)
          expect(stats).to_not receive(:log)
          call_contract
        end
      end

      context "when only one guarantee is true" do
        it "catches an error" do
          contract_kwargs.merge!(foo: false, bar: true)
          expect(stats).to receive(:log).
            with(:guarantee_failure,
                 {checked: %w(guarantee_bar guarantee_foo),
                  input: {args: [], kwargs: {foo: false, bar: true}},
                  sample_path: kind_of(String)},
                 nil)
          call_contract
        end
      end

      context "when unexpected error" do
        let(:contract) do
          Class.new(SimpleContracts::Base) do
            private

            def guarantee_foo
              raise "Boom!"
            end
          end
        end

        it "catches an error" do
          expect(stats).to receive(:log).
            with(:unexpected_error,
                 {checked: ["guarantee_foo"],
                  input: {args: [], kwargs: {}},
                  sample_path: kind_of(String)},
                 kind_of(RuntimeError))
          call_contract
        end
      end
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

    context "when synchronus verification" do
      let(:contract_kwargs) { {async: false} }

      context "when all expectations are false" do
        it do
          contract_kwargs.merge!(foo: false, bar: false)
          expect(stats).to receive(:log).
            with(:expectation_failure,
                 {checked: %w(expect_bar expect_foo),
                  input: {args: [], kwargs: {foo: false, bar: false}},
                  sample_path: kind_of(String)},
                 nil)
          expect { call_contract }.to raise_error(SimpleContracts::ExpectationsError)
        end
      end

      context "when all expectations are true" do
        it do
          contract_kwargs.merge!(foo: true, bar: true)
          expect(stats).to receive(:log).
            with("expect_bar",
                 {checked: %w(expect_bar),
                  input: {args: [], kwargs: {foo: true, bar: true}},
                  sample_path: kind_of(String)},
                 nil)
          call_contract
        end
      end

      context "when only one expectation is true" do
        it do
          contract_kwargs.merge!(foo: true, bar: false)
          expect(stats).to receive(:log).
            with("expect_foo",
                 {checked: %w(expect_bar expect_foo),
                  input: {args: [], kwargs: {foo: true, bar: false}},
                  sample_path: kind_of(String)},
                 nil)
          call_contract
        end
      end
    end

    context "when asynchronus verification" do
      before do
        allow_any_instance_of(contract).
          to receive(:concurrent_options).
          and_return(executor: :immediate)
      end

      context "when all expectations are false" do
        it "catches an error" do
          contract_kwargs.merge!(foo: false, bar: false)
          expect(stats).to receive(:log).
            with(:expectation_failure,
                 {checked: %w(expect_bar expect_foo),
                  input: {args: [], kwargs: {foo: false, bar: false}},
                  sample_path: kind_of(String)},
                 nil)
          call_contract
        end
      end

      context "when all expectations are true" do
        it "does not catche an error" do
          contract_kwargs.merge!(foo: true, bar: true)
          expect(stats).to receive(:log).
            with("expect_bar",
                 {checked: %w(expect_bar),
                  input: {args: [], kwargs: {foo: true, bar: true}},
                  sample_path: kind_of(String)},
                 nil)
          call_contract
        end
      end

      context "when only one expectation is true" do
        it "catches an error" do
          contract_kwargs.merge!(foo: true, bar: false)
          expect(stats).to receive(:log).
            with("expect_foo",
                 {checked: %w(expect_bar expect_foo),
                  input: {args: [], kwargs: {foo: true, bar: false}},
                  sample_path: kind_of(String)},
                 nil)
          call_contract
        end
      end
    end
  end
end
