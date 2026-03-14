# frozen_string_literal: true

module Legion
  module Extensions
    module SignalDetection
      module Helpers
        class DetectionEngine
          def initialize
            @detectors = {}
          end

          def create_detector(domain:)
            raise ArgumentError, "max detectors reached (#{Constants::MAX_DETECTORS})" if @detectors.size >= Constants::MAX_DETECTORS

            detector = Detector.new(domain: domain)
            @detectors[detector.id] = detector
            detector
          end

          def record_trial(detector_id:, signal_present:, responded_present:)
            detector = fetch!(detector_id)
            outcome  = classify_outcome(signal_present: signal_present, responded_present: responded_present)
            detector.record_trial(outcome: outcome)
            { detector_id: detector_id, outcome: outcome, trial_count: detector.trial_count }
          end

          def compute_sensitivity(detector_id:)
            detector = fetch!(detector_id)
            {
              detector_id:       detector_id,
              d_prime:           detector.compute_dprime,
              criterion:         detector.compute_criterion,
              accuracy:          detector.accuracy,
              hit_rate:          detector.hit_rate,
              false_alarm_rate:  detector.false_alarm_rate,
              sensitivity_label: detector.sensitivity_label,
              bias_label:        detector.bias_label
            }
          end

          def adjust_bias(detector_id:, amount:)
            detector = fetch!(detector_id)
            detector.adjust_criterion(amount: amount)
            { detector_id: detector_id, criterion: detector.criterion, bias_label: detector.bias_label }
          end

          def best_detectors(limit: 5)
            @detectors.values
                      .sort_by { |d| -d.sensitivity }
                      .first(limit)
                      .map(&:to_h)
          end

          def by_domain(domain:)
            @detectors.values.select { |d| d.domain == domain }.map(&:to_h)
          end

          def optimal_criterion(detector_id:, signal_probability: 0.5)
            detector = fetch!(detector_id)
            # Optimal criterion for equal cost: c* = 0.5 * ln((1-p)/p) in likelihood ratio terms
            # In SDT criterion units: shift from neutral based on prior probability
            prior_ratio = (1.0 - signal_probability) / signal_probability.clamp(0.001, 0.999)
            optimal = 0.5 * Math.log(prior_ratio)
            {
              detector_id:        detector_id,
              optimal_criterion:  Constants.clamp_criterion(optimal),
              current_criterion:  detector.criterion,
              signal_probability: signal_probability
            }
          end

          def roc_point(detector_id:)
            detector = fetch!(detector_id)
            {
              detector_id:      detector_id,
              hit_rate:         detector.hit_rate,
              false_alarm_rate: detector.false_alarm_rate,
              d_prime:          detector.sensitivity
            }
          end

          def decay_all
            count = 0
            @detectors.each_value do |detector|
              next if detector.trial_count.zero?

              detector.adjust_criterion(amount: Constants::DECAY_RATE * -detector.criterion.clamp(-1, 1))
              count += 1
            end
            count
          end

          def get(detector_id)
            @detectors[detector_id]
          end

          def count
            @detectors.size
          end

          def to_h
            {
              detector_count: @detectors.size,
              detectors:      @detectors.transform_values(&:to_h)
            }
          end

          private

          def fetch!(detector_id)
            @detectors.fetch(detector_id) { raise KeyError, "detector not found: #{detector_id}" }
          end

          def classify_outcome(signal_present:, responded_present:)
            if signal_present && responded_present then :hit
            elsif signal_present && !responded_present then :miss
            elsif !signal_present && responded_present then :false_alarm
            else :correct_rejection
            end
          end
        end
      end
    end
  end
end
