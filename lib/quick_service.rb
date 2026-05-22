# frozen_string_literal: true

require 'active_support/core_ext/hash/indifferent_access'
require 'active_support/core_ext/object/blank'
require 'active_support/core_ext/object/try'

require 'quick_service/version'
require 'quick_service/configuration'

# Namespace for all objects in QuickService.
module QuickService
  autoload :Service, 'quick_service/service'
end
