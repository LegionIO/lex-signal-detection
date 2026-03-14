# frozen_string_literal: true

module Legion
  module Extensions
    module SignalDetection
      module Runners
        module SignalDetection
          include Legion::Extensions::Helpers::Lex if Legion::Extensions.const_defined?(:Helpers) &&
                                                      Legion::Extensions::Helpers.const_defined?(:Lex)

          def create_detector(domain:, **)
            detector = detection_engine.create_detector(domain: domain)
            Legion::Logging.info "[signal_detection] created detector id=#{detector.id[0..7]} domain=#{domain}"
            { created: true, detector_id: detector.id, domain: domain }
          rescue ArgumentError => e
            Legion::Logging.warn "[signal_detection] create_detector failed: #{e.message}"
            { created: false, reason: e.message }
          end

          def record_detection_trial(detector_id:, signal_present:, responded_present:, **)
            result = detection_engine.record_trial(
              detector_id:       detector_id,
              signal_present:    signal_present,
              responded_present: responded_present
            )
            Legion::Logging.debug "[signal_detection] trial: id=#{detector_id[0..7]} outcome=#{result[:outcome]} count=#{result[:trial_count]}"
            result
          rescue KeyError => e
            Legion::Logging.warn "[signal_detection] record_trial failed: #{e.message}"
            { recorded: false, reason: :not_found }
          end

          def compute_detector_sensitivity(detector_id:, **)
            result = detection_engine.compute_sensitivity(detector_id: detector_id)
            Legion::Logging.debug "[signal_detection] sensitivity: id=#{detector_id[0..7]} " \
                                  "d_prime=#{result[:d_prime].round(3)} label=#{result[:sensitivity_label]}"
            result
          rescue KeyError => e
            Legion::Logging.warn "[signal_detection] compute_sensitivity failed: #{e.message}"
            { found: false, reason: :not_found }
          end

          def adjust_detector_bias(detector_id:, amount:, **)
            result = detection_engine.adjust_bias(detector_id: detector_id, amount: amount)
            Legion::Logging.debug "[signal_detection] bias adjusted: id=#{detector_id[0..7]} " \
                                  "criterion=#{result[:criterion].round(3)} label=#{result[:bias_label]}"
            result
          rescue KeyError => e
            Legion::Logging.warn "[signal_detection] adjust_bias failed: #{e.message}"
            { adjusted: false, reason: :not_found }
          end

          def best_detectors(limit: 5, **)
            detectors = detection_engine.best_detectors(limit: limit)
            Legion::Logging.debug "[signal_detection] best detectors: count=#{detectors.size} limit=#{limit}"
            { detectors: detectors, count: detectors.size }
          end

          def domain_detectors(domain:, **)
            detectors = detection_engine.by_domain(domain: domain)
            Legion::Logging.debug "[signal_detection] domain detectors: domain=#{domain} count=#{detectors.size}"
            { detectors: detectors, count: detectors.size, domain: domain }
          end

          def optimal_detector_criterion(detector_id:, signal_probability: 0.5, **)
            result = detection_engine.optimal_criterion(
              detector_id:        detector_id,
              signal_probability: signal_probability
            )
            Legion::Logging.debug "[signal_detection] optimal criterion: id=#{detector_id[0..7]} optimal=#{result[:optimal_criterion].round(3)}"
            result
          rescue KeyError => e
            Legion::Logging.warn "[signal_detection] optimal_criterion failed: #{e.message}"
            { found: false, reason: :not_found }
          end

          def detector_roc_point(detector_id:, **)
            result = detection_engine.roc_point(detector_id: detector_id)
            Legion::Logging.debug "[signal_detection] roc point: id=#{detector_id[0..7]} " \
                                  "hr=#{result[:hit_rate].round(3)} far=#{result[:false_alarm_rate].round(3)}"
            result
          rescue KeyError => e
            Legion::Logging.warn "[signal_detection] roc_point failed: #{e.message}"
            { found: false, reason: :not_found }
          end

          def update_signal_detection(**)
            decayed = detection_engine.decay_all
            Legion::Logging.debug "[signal_detection] decay cycle: detectors_updated=#{decayed}"
            { decayed: decayed }
          end

          def signal_detection_stats(**)
            {
              total_detectors: detection_engine.count,
              top_detectors:   detection_engine.best_detectors(limit: 3)
            }
          end

          private

          def detection_engine
            @detection_engine ||= Helpers::DetectionEngine.new
          end
        end
      end
    end
  end
end
