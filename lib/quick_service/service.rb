# QuickService::Service serves as a base for creating service objects.
# It standardizes the way services are called and how they report a
# success/failure result back to the caller.
module QuickService
  class Service
    attr_reader :params, :result

    # Unique tag for the throw/catch used to unwind a halted service.
    # A thrown HALT is not an exception, so it can never be intercepted by
    # a `rescue` inside a service's `call`.
    HALT = Object.new.freeze
    private_constant :HALT

    # Initializes the service.
    # @param params [Hash] The parameters to be passed to the service.
    def initialize(params = {})
      if QuickService.configuration.enforce_interface
        raise NotImplementedError,
              'Subclasses must implement the initialize method ' \
              'because `enforce_interface` is set to true'
      end
      @params = params
      @result = ServiceResult.new
    end

    class << self
      # Calls the service and handles any QuickService failure.
      # @param params [Hash] Arguments to pass to the service.
      # @return [ServiceResult] The result of the service call.
      def call(params = {})
        service = new(**params)
        catch(HALT) { service.call }
        service.result || ServiceResult.new
      rescue ServiceError => e
        service.result || e.result
      end

      # Like `.call`, but re-raises a ServiceError when the result failed.
      # Useful for nested services where a failure should cascade upwards.
      # @param params [Hash] Arguments to pass to the service.
      # @return [ServiceResult] The result of the service call.
      def call!(params = {})
        result = call(params)
        return result || ServiceResult.new unless result.fail?

        raise ServiceError, result
      end
    end

    # The main method to be implemented by subclasses.
    def call
      raise NotImplementedError, 'Subclasses must implement the call method'
    end

    protected

    # Marks the service as failed without stopping execution.
    # @param errors [Any] Optional errors to be returned in the result.
    def fail(errors = nil)
      @result = ServiceResult.new(success: false, errors: errors)
    end

    # Marks the service as successful without stopping execution.
    # @param data [Any] Optional data to be returned in the result.
    def success(data = nil)
      @result = ServiceResult.new(success: true, data: data)
    end

    # Marks the service as failed and stops the execution of the service.
    # @param errors [Any] Errors to be returned in the result.
    def fail!(errors = nil)
      @result = ServiceResult.new(success: false, errors: errors)
      throw HALT
    end

    # Marks the service as successful and stops the execution of the service.
    # @param data [Any] Optional data to be returned in the result.
    def success!(data = nil)
      @result = ServiceResult.new(success: true, data: data)
      throw HALT
    end

    # Validates the service using a form object, failing softly when invalid.
    # @param key [Symbol] Key under which the errors will be stored.
    # @param form [ActiveModel::Model] The form object to validate.
    def validate_with(key, form)
      fail({ key => form.errors.messages }) unless form.valid?
    end

    # Validates the service using a form object, halting when invalid.
    # @param key [Symbol] Key under which the errors will be stored.
    # @param form [ActiveModel::Model] The form object to validate.
    def validate_with!(key, form)
      fail!({ key => form.errors.messages }) unless form.valid?
    end

    # Validates several form objects, collecting every error before halting.
    # @param pipeline [Hash{Symbol => ActiveModel::Model}] forms to validate.
    def validate_pipeline(pipeline)
      pipeline.each do |key, form|
        fail_and_merge({ key => form.errors.messages }) unless form.valid?
      end
      fail!(@result.errors) if @result.failed?
    end

    class ServiceResult
      attr_reader :success, :data, :errors

      # Initializes the ServiceResult.
      # @param success [Boolean] Indicates if the service call was successful.
      # @param data [Any] The data returned by the service.
      # @param errors [Any] The errors returned by the service.
      def initialize(success: true, data: nil, errors: nil)
        @success = success
        @data = (data || {}).with_indifferent_access
        @errors = (errors.to_h || {}).with_indifferent_access
      end

      # Checks if the service call was successful.
      # @return [Boolean] True if successful, false otherwise.
      def succeeded?
        success
      end

      alias success? succeeded?

      # Checks if the service call failed.
      # @return [Boolean] True if failed, false otherwise.
      def failed?
        !success
      end

      alias fail? failed?

      # Reads `key` from the result payload (data on success, errors on
      # failure). Raises KeyError when the key is absent. This is the
      # canonical accessor: unlike `result.key`, it never collides with a
      # real method name.
      def [](key)
        payload.fetch(key) do
          raise KeyError, "unknown key #{key.inspect}; result has: #{payload.keys}"
        end
      end

      # Reports the keys exposed by the result, so `respond_to?`, `try`, and
      # serializers behave correctly.
      def respond_to_missing?(name, include_private = false)
        payload.key?(name) || super
      end

      # Reads `name` from the result payload: `data` on success, `errors` on
      # failure. Raises NoMethodError for unknown keys so that typos surface.
      def method_missing(name, *args, &block)
        return payload[name] if payload.key?(name)

        super
      end

      private

      # The hash backing the dynamic readers.
      def payload
        succeeded? ? @data : @errors
      end
    end

    class ServiceError < StandardError
      attr_reader :result

      def initialize(result)
        @result = result
        super(build_message(result))
      end

      private

      def build_message(result)
        errors = result.try(:errors)
        errors.present? ? "QuickService failed: #{errors.to_h}" : 'QuickService failed'
      end
    end

    private

    def fail_and_merge(errors)
      @result = if @result.blank?
                  ServiceResult.new(success: false, errors: errors)
                else
                  ServiceResult.new(success: false, errors: errors.merge!(@result.errors))
                end
    end
  end
end
