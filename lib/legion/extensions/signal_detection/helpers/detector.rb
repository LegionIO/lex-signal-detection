# frozen_string_literal: true

require 'securerandom'

module Legion
  module Extensions
    module SignalDetection
      module Helpers
        class Detector
          include Constants

          attr_reader :id, :domain, :hits, :misses, :false_alarms, :correct_rejections,
                      :trial_count, :created_at, :last_trial_at, :sensitivity, :criterion

          def initialize(domain:)
            @id               = SecureRandom.uuid
            @domain           = domain
            @sensitivity      = Constants::DEFAULT_SENSITIVITY
            @criterion        = Constants::DEFAULT_CRITERION
            @hits             = 0
            @misses           = 0
            @false_alarms     = 0
            @correct_rejections = 0
            @trial_count      = 0
            @created_at       = Time.now.utc
            @last_trial_at    = nil
          end

          def record_trial(outcome:)
            raise ArgumentError, "invalid outcome: #{outcome}" unless Constants::TRIAL_OUTCOMES.include?(outcome)

            case outcome
            when :hit               then @hits += 1
            when :miss              then @misses += 1
            when :false_alarm       then @false_alarms += 1
            when :correct_rejection then @correct_rejections += 1
            end

            @trial_count   += 1
            @last_trial_at  = Time.now.utc

            update_sensitivity
          end

          def hit_rate
            signal_total = @hits + @misses + 1
            (@hits + 0.5) / signal_total.to_f
          end

          def false_alarm_rate
            noise_total = @false_alarms + @correct_rejections + 1
            (@false_alarms + 0.5) / noise_total.to_f
          end

          def compute_dprime
            d = z_score(hit_rate) - z_score(false_alarm_rate)
            Constants.clamp_sensitivity(d)
          end

          def compute_criterion
            c = -0.5 * (z_score(hit_rate) + z_score(false_alarm_rate))
            Constants.clamp_criterion(c)
          end

          def accuracy
            return 0.0 if @trial_count.zero?

            (@hits + @correct_rejections).to_f / @trial_count
          end

          def sensitivity_label
            Constants.sensitivity_label(@sensitivity)
          end

          def bias_label
            Constants.bias_label(@criterion)
          end

          def adjust_criterion(amount:)
            @criterion = Constants.clamp_criterion(@criterion + amount)
          end

          def to_h
            {
              id:                 @id,
              domain:             @domain,
              sensitivity:        @sensitivity,
              criterion:          @criterion,
              hits:               @hits,
              misses:             @misses,
              false_alarms:       @false_alarms,
              correct_rejections: @correct_rejections,
              trial_count:        @trial_count,
              hit_rate:           hit_rate,
              false_alarm_rate:   false_alarm_rate,
              accuracy:           accuracy,
              sensitivity_label:  sensitivity_label,
              bias_label:         bias_label,
              created_at:         @created_at,
              last_trial_at:      @last_trial_at
            }
          end

          private

          def update_sensitivity
            return if @trial_count < 2

            @sensitivity = compute_dprime
            @criterion   = compute_criterion
          end

          def z_score(probability)
            prob = probability.clamp(0.001, 0.999)
            Math.sqrt(2.0) * erfinv((2.0 * prob) - 1.0)
          end

          def erfinv(val)
            # Winitzki (2008) rational approximation for inverse error function
            a = 0.147
            ln_term = Math.log(1.0 - (val * val))
            two_pi_a = (2.0 / (Math::PI * a))
            half_ln = ln_term / 2.0

            inner = two_pi_a + half_ln
            Math.sqrt(Math.sqrt((inner * inner) - (ln_term / a)) - inner) * (val.negative? ? -1 : 1)
          end
        end
      end
    end
  end
end
