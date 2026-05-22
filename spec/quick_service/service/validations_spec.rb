# frozen_string_literal: true

RSpec.describe 'Service validations' do
  # A minimal stand-in for an ActiveModel form object: the validation helpers
  # only need an object that responds to `#valid?` and `#errors.messages`.
  StubForm = Struct.new(:valid, :messages, keyword_init: true) do
    def valid?
      valid
    end

    def errors
      Struct.new(:messages).new(messages || {})
    end
  end

  it '#validate_with records a soft failure when the form is invalid' do
    service = Class.new(QuickService::Service) do
      def call
        validate_with(:user, params[:form])
        # no #success afterwards: the soft failure stands as the result
      end
    end

    form = StubForm.new(valid: false, messages: { email: ["can't be blank"] })
    result = service.call(form: form)

    expect(result).to be_fail
    expect(result.user).to eq('email' => ["can't be blank"])
  end

  it '#validate_with is soft: a later #success overrides the failure' do
    service = Class.new(QuickService::Service) do
      def call
        validate_with(:user, params[:form])
        success(saved: true) # soft failure gets overwritten
      end
    end

    form = StubForm.new(valid: false, messages: { email: ["can't be blank"] })
    result = service.call(form: form)

    expect(result).to be_success
    expect(result.saved).to be(true)
  end

  it '#validate_with! fails and halts execution' do
    service = Class.new(QuickService::Service) do
      def call
        validate_with!(:user, params[:form])
        success(reached: true)
      end
    end

    form = StubForm.new(valid: false, messages: { name: ['is too short'] })
    result = service.call(form: form)

    expect(result).to be_fail
    expect(result.user).to eq('name' => ['is too short'])
    expect { result.reached }.to raise_error(NoMethodError)
  end

  it '#validate_with passes through when the form is valid' do
    service = Class.new(QuickService::Service) do
      def call
        validate_with(:user, params[:form])
        success(ok: true)
      end
    end

    result = service.call(form: StubForm.new(valid: true))

    expect(result).to be_success
    expect(result.ok).to be(true)
  end

  it '#validate_pipeline collects errors from every form before halting' do
    service = Class.new(QuickService::Service) do
      def call
        validate_pipeline(
          user: params[:user_form],
          address: params[:address_form]
        )
        success(reached: true)
      end
    end

    result = service.call(
      user_form: StubForm.new(valid: false, messages: { email: ['invalid'] }),
      address_form: StubForm.new(valid: false, messages: { zip: ['invalid'] })
    )

    expect(result).to be_fail
    expect(result.user).to eq('email' => ['invalid'])
    expect(result.address).to eq('zip' => ['invalid'])
  end
end
