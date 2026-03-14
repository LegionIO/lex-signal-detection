# frozen_string_literal: true

require 'legion/extensions/signal_detection/version'
require 'legion/extensions/signal_detection/helpers/constants'
require 'legion/extensions/signal_detection/helpers/detector'
require 'legion/extensions/signal_detection/helpers/detection_engine'
require 'legion/extensions/signal_detection/runners/signal_detection'

module Legion
  module Extensions
    module SignalDetection
      extend Legion::Extensions::Core if Legion::Extensions.const_defined? :Core
    end
  end
end
