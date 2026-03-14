# frozen_string_literal: true

require 'legion/extensions/signal_detection/helpers/constants'
require 'legion/extensions/signal_detection/helpers/detector'
require 'legion/extensions/signal_detection/helpers/detection_engine'
require 'legion/extensions/signal_detection/runners/signal_detection'

module Legion
  module Extensions
    module SignalDetection
      class Client
        include Runners::SignalDetection

        def initialize(**)
          @detection_engine = Helpers::DetectionEngine.new
        end

        private

        attr_reader :detection_engine
      end
    end
  end
end
