module QuickService
  class Configuration
    attr_accessor :enforce_interface

    def initialize
      @enforce_interface = false # Default value
    end
  end

  # Returns the QuickService::Configuration instance.
  def self.configuration
    @configuration ||= Configuration.new
  end

  # Yields the QuickService::Configuration instance for tweaking.
  #
  #   QuickService.configure do |config|
  #     config.enforce_interface = true
  #   end
  def self.configure
    yield(configuration) if block_given?
  end
end
