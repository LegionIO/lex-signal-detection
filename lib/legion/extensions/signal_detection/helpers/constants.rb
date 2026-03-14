# frozen_string_literal: true

module Legion
  module Extensions
    module SignalDetection
      module Helpers
        module Constants
          MAX_DETECTORS = 100
          MAX_TRIALS    = 1000
          MAX_HISTORY   = 300

          DEFAULT_SENSITIVITY = 1.0
          SENSITIVITY_FLOOR   = 0.0
          SENSITIVITY_CEILING = 5.0

          DEFAULT_CRITERION = 0.0
          CRITERION_FLOOR   = -3.0
          CRITERION_CEILING = 3.0

          LEARNING_RATE = 0.05
          DECAY_RATE    = 0.01

          TRIAL_OUTCOMES = %i[hit miss false_alarm correct_rejection].freeze

          SENSITIVITY_LABELS = {
            (3.0..)     => :exceptional,
            (2.0...3.0) => :excellent,
            (1.0...2.0) => :good,
            (0.5...1.0) => :moderate,
            (..0.5)     => :poor
          }.freeze

          BIAS_LABELS = {
            (1.0..)       => :very_conservative,
            (0.3...1.0)   => :conservative,
            (-0.3...0.3)  => :neutral,
            (-1.0...-0.3) => :liberal,
            (...-1.0)     => :very_liberal
          }.freeze

          module_function

          def sensitivity_label(d_prime)
            SENSITIVITY_LABELS.find { |range, _| range.cover?(d_prime) }&.last || :poor
          end

          def bias_label(criterion)
            BIAS_LABELS.find { |range, _| range.cover?(criterion) }&.last || :neutral
          end

          def clamp_sensitivity(value)
            value.clamp(SENSITIVITY_FLOOR, SENSITIVITY_CEILING)
          end

          def clamp_criterion(value)
            value.clamp(CRITERION_FLOOR, CRITERION_CEILING)
          end
        end
      end
    end
  end
end
