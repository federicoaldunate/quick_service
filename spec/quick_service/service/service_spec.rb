# frozen_string_literal: true

RSpec.describe 'Service usages' do
  ######
  # Test .call needs an override
  ######

  it '.call needs to be overridden' do
    service = Class.new(QuickService::Service)

    expect { service.call }.to raise_error(
      NotImplementedError
    ).with_message('Subclasses must implement the call method')
  end

  ######
  # Test .call
  ######

  it '.call - success by default' do
    service = Class.new(QuickService::Service) do
      def call; end
    end

    result = service.call(email: 'service@example.com')

    expect(result).to be_success
  end

  it '.call with #success && data' do
    service = Class.new(QuickService::Service) do
      def call
        success(email: params[:email])
      end
    end

    result = service.call(email: 'service@example.com')

    expect(result).to be_success
    expect(result.email).to eq('service@example.com')
  end

  it '.call with #fail!' do
    service = Class.new(QuickService::Service) do
      def call
        fail!(email: params[:email])
      end
    end

    result = service.call(email: 'service@example.com')

    expect(result).to be_fail
    expect(result.email).to eq('service@example.com')
  end

  it '.call with #success!' do
    service = Class.new(QuickService::Service) do
      def call
        success!(email: params[:email])
        fail!(email: 'unreachable@example.com')
      end
    end

    result = service.call(email: 'service@example.com')

    expect(result).to be_success
    expect(result.email).to eq('service@example.com')
  end

  it '#fail! halts even through a rescue inside #call' do
    service = Class.new(QuickService::Service) do
      def call
        fail!(reason: 'halted')
      rescue StandardError => e
        success(swallowed: e.class.name)
      end
    end

    result = service.call

    expect(result).to be_fail
    expect(result[:reason]).to eq('halted')
  end

  it '.call - fail on raising error' do
    service = Class.new(QuickService::Service) do
      def call
        raise StandardError, 'Something wrong'
      end
    end

    expect { service.call }.to raise_error(
      StandardError
    ).with_message('Something wrong')
  end

  ######
  # Test enforcing the interface of the service
  ######

  context 'when the configuration is set to enforce the interface' do
    before do
      QuickService.configure do |config|
        config.enforce_interface = true
      end
    end

    it 'raises an error when the #initialize method is not implemented' do
      service = Class.new(QuickService::Service) do
        def call; end
      end

      expect { service.call }.to raise_error(
        NotImplementedError
      ).with_message(
        'Subclasses must implement the initialize '\
        'method because `enforce_interface` is set to true'
      )
    end

    it 'does not raise an error when the #initialize method is implemented' do
      service = Class.new(QuickService::Service) do
        def initialize; end
        def call; end
      end

      expect { service.call }.not_to raise_error
    end

    it '.call - fails on missing arguments' do
      service = Class.new(QuickService::Service) do
        def initialize(email:)
          @email = email
        end

        def call
          success(email: @email)
        end
      end

      expect { service.call }.to raise_error(
        ArgumentError
      ).with_message('missing keyword: :email')
    end

    it '.call - success with arguments' do
      service = Class.new(QuickService::Service) do
        def initialize(email:)
          @email = email
        end

        def call
          success(email: @email)
        end
      end

      result = service.call(email: 'fede@example.com')

      expect(result).to be_success
      expect(result.email).to eq('fede@example.com')
    end

    it '.call - success default with arguments' do
      service = Class.new(QuickService::Service) do
        def initialize(email:)
          @email = email
        end

        def call; end
      end

      result = service.call(email: 'fede@example.com')

      expect(result).to be_success
      expect { result.email }.to raise_error(NoMethodError)
    end

    ######
    # Test the different behavior of #success #fail #fail!
    ######

    it 'call #success twice' do
      service = Class.new(QuickService::Service) do
        def initialize(email:)
          @email = email
        end

        def call
          success(email: 'hi@example.com')
          success(email: @email)
        end
      end

      result = service.call(email: 'service@example.com')

      expect(result).to be_success
      expect(result.email).to eq('service@example.com')
    end

    it 'call #fail twice' do
      service = Class.new(QuickService::Service) do
        def initialize(email:)
          @email = email
        end

        def call
          fail(email: 'hi@example.com')
          fail(email: @email)
        end
      end

      result = service.call(email: 'service@example.com')

      expect(result).to be_fail
      expect(result.email).to eq('service@example.com')
    end

    it 'call #fail! twice' do
      service = Class.new(QuickService::Service) do
        def initialize(email:)
          @email = email
        end

        def call
          fail!(email: 'hi@example.com')
          fail!(email: @email)
        end
      end

      result = service.call(email: 'service@example.com')

      expect(result).to be_fail
      expect(result.email).to eq('hi@example.com')
    end

    it '#fail then #success' do
      service = Class.new(QuickService::Service) do
        def initialize(email:)
          @email = email
        end

        def call
          fail(email: 'hi@example.com')
          success(email: @email)
        end
      end

      result = service.call(email: 'service@example.com')

      expect(result).to be_success
      expect(result.email).to eq('service@example.com')
    end

    it '#fail! halts before a later #success' do
      service = Class.new(QuickService::Service) do
        def initialize(email:)
          @email = email
        end

        def call
          fail!(email: 'hi@example.com')
          success(email: @email)
        end
      end

      result = service.call(email: 'service@example.com')

      expect(result).to be_fail
      expect(result.email).to eq('hi@example.com')
    end

    context 'testing nested services with call' do
      it 'a failure in a nested .call does not affect the caller' do
        inner = Class.new(QuickService::Service) do
          def initialize(email:)
            @email = email
          end

          def call
            fail!(email: @email)
          end
        end

        parent = Class.new(QuickService::Service) do
          def initialize(email:)
            @email = email
          end

          define_method(:call) do
            inner.call(email: 'inner@service.com')
            success(email: @email)
          end
        end

        result = parent.call(email: 'outer@service.com')

        expect(result).to be_success
        expect(result.email).to eq('outer@service.com')
      end
    end

    context 'testing nested services with call!' do
      it 'a failure in a nested .call! cascades to the caller' do
        inner = Class.new(QuickService::Service) do
          def initialize(email:)
            @email = email
          end

          def call
            fail!(email: @email)
          end
        end

        parent = Class.new(QuickService::Service) do
          def initialize(email:)
            @email = email
          end

          define_method(:call) do
            inner.call!(email: 'inner@service.com')
            success(email: @email)
          end
        end

        result = parent.call(email: 'outer@service.com')

        expect(result).to be_fail
        expect(result.email).to eq('inner@service.com')
      end
    end

    context 'testing three levels of nested services' do
      it 'a third-level failure does not cascade when the middle uses .call' do
        third = Class.new(QuickService::Service) do
          def initialize; end

          def call
            fail!(level: 'three')
          end
        end

        second = Class.new(QuickService::Service) do
          def initialize; end

          define_method(:call) do
            third.call
            success(level: 'two')
          end
        end

        first = Class.new(QuickService::Service) do
          def initialize; end

          define_method(:call) do
            second.call!
            success(level: 'one')
          end
        end

        result = first.call

        expect(result).to be_success
        expect(result[:level]).to eq('one')
      end
    end
  end
end
