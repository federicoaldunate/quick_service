# frozen_string_literal: true

RSpec.describe QuickService::Service::ServiceResult do
  def service(&block)
    Class.new(QuickService::Service) do
      define_method(:call, &block)
    end
  end

  it 'exposes data keys of a successful result' do
    result = service { success(email: 'fede@example.com') }.call

    expect(result).to respond_to(:email)
    expect(result.email).to eq('fede@example.com')
  end

  it 'exposes error keys of a failed result' do
    result = service { fail!(email: "can't be blank") }.call

    expect(result).to respond_to(:email)
    expect(result.email).to eq("can't be blank")
  end

  it 'does not respond to unknown keys' do
    result = service { success(email: 'fede@example.com') }.call

    expect(result).not_to respond_to(:unknown)
  end

  it 'raises NoMethodError for unknown keys' do
    result = service { success(email: 'fede@example.com') }.call

    expect { result.unknown }.to raise_error(NoMethodError)
  end

  it 'plays well with #try for optional keys' do
    result = service { success(email: 'fede@example.com') }.call

    expect(result.try(:email)).to eq('fede@example.com')
    expect(result.try(:unknown)).to be_nil
  end

  it 'reads values via [] with indifferent access' do
    result = service { success(email: 'fede@example.com') }.call

    expect(result[:email]).to eq('fede@example.com')
    expect(result['email']).to eq('fede@example.com')
  end

  it 'raises KeyError for an unknown [] key' do
    result = service { success(email: 'fede@example.com') }.call

    expect { result[:unknown] }.to raise_error(KeyError, /unknown key :unknown/)
  end

  it '[] reaches keys shadowed by real method names' do
    result = service { success(data: 'shadowed') }.call

    expect(result.data).to be_a(Hash)       # the attr_reader wins
    expect(result[:data]).to eq('shadowed') # [] reaches the payload
  end
end
