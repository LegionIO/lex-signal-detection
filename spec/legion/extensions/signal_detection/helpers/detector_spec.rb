# frozen_string_literal: true

RSpec.describe Legion::Extensions::SignalDetection::Helpers::Detector do
  subject(:detector) { described_class.new(domain: :threat) }

  describe '#initialize' do
    it 'assigns an id' do
      expect(detector.id).to match(/\A[0-9a-f-]{36}\z/)
    end

    it 'sets domain' do
      expect(detector.domain).to eq(:threat)
    end

    it 'starts with default sensitivity' do
      expect(detector.sensitivity).to eq(Legion::Extensions::SignalDetection::Helpers::Constants::DEFAULT_SENSITIVITY)
    end

    it 'starts with default criterion' do
      expect(detector.criterion).to eq(Legion::Extensions::SignalDetection::Helpers::Constants::DEFAULT_CRITERION)
    end

    it 'starts with zero counts' do
      expect(detector.hits).to eq(0)
      expect(detector.misses).to eq(0)
      expect(detector.false_alarms).to eq(0)
      expect(detector.correct_rejections).to eq(0)
      expect(detector.trial_count).to eq(0)
    end
  end

  describe '#record_trial' do
    it 'increments hits on :hit' do
      detector.record_trial(outcome: :hit)
      expect(detector.hits).to eq(1)
      expect(detector.trial_count).to eq(1)
    end

    it 'increments misses on :miss' do
      detector.record_trial(outcome: :miss)
      expect(detector.misses).to eq(1)
    end

    it 'increments false_alarms on :false_alarm' do
      detector.record_trial(outcome: :false_alarm)
      expect(detector.false_alarms).to eq(1)
    end

    it 'increments correct_rejections on :correct_rejection' do
      detector.record_trial(outcome: :correct_rejection)
      expect(detector.correct_rejections).to eq(1)
    end

    it 'raises on invalid outcome' do
      expect { detector.record_trial(outcome: :bogus) }.to raise_error(ArgumentError, /invalid outcome/)
    end

    it 'updates last_trial_at' do
      expect(detector.last_trial_at).to be_nil
      detector.record_trial(outcome: :hit)
      expect(detector.last_trial_at).to be_a(Time)
    end
  end

  describe '#hit_rate' do
    it 'applies Hautus correction' do
      expect(detector.hit_rate).to be_between(0.0, 1.0)
    end

    it 'increases as hits accumulate' do
      before = detector.hit_rate
      5.times { detector.record_trial(outcome: :hit) }
      expect(detector.hit_rate).to be > before
    end
  end

  describe '#false_alarm_rate' do
    it 'applies Hautus correction' do
      expect(detector.false_alarm_rate).to be_between(0.0, 1.0)
    end

    it 'increases as false alarms accumulate' do
      before = detector.false_alarm_rate
      5.times { detector.record_trial(outcome: :false_alarm) }
      expect(detector.false_alarm_rate).to be > before
    end
  end

  describe '#compute_dprime' do
    it 'returns a float within sensitivity bounds' do
      5.times { detector.record_trial(outcome: :hit) }
      2.times { detector.record_trial(outcome: :miss) }
      2.times { detector.record_trial(outcome: :false_alarm) }
      3.times { detector.record_trial(outcome: :correct_rejection) }
      expect(detector.compute_dprime).to be_between(
        Legion::Extensions::SignalDetection::Helpers::Constants::SENSITIVITY_FLOOR,
        Legion::Extensions::SignalDetection::Helpers::Constants::SENSITIVITY_CEILING
      )
    end

    it 'is positive when hit_rate > false_alarm_rate' do
      10.times { detector.record_trial(outcome: :hit) }
      detector.record_trial(outcome: :false_alarm)
      expect(detector.compute_dprime).to be > 0
    end
  end

  describe '#compute_criterion' do
    it 'returns a float within criterion bounds' do
      5.times { detector.record_trial(outcome: :hit) }
      5.times { detector.record_trial(outcome: :miss) }
      result = detector.compute_criterion
      expect(result).to be_between(
        Legion::Extensions::SignalDetection::Helpers::Constants::CRITERION_FLOOR,
        Legion::Extensions::SignalDetection::Helpers::Constants::CRITERION_CEILING
      )
    end
  end

  describe '#accuracy' do
    it 'returns 0.0 with no trials' do
      expect(detector.accuracy).to eq(0.0)
    end

    it 'computes correctly' do
      3.times { detector.record_trial(outcome: :hit) }
      2.times { detector.record_trial(outcome: :correct_rejection) }
      expect(detector.accuracy).to eq(1.0)
    end

    it 'decreases with errors' do
      2.times { detector.record_trial(outcome: :hit) }
      2.times { detector.record_trial(outcome: :miss) }
      2.times { detector.record_trial(outcome: :false_alarm) }
      2.times { detector.record_trial(outcome: :correct_rejection) }
      expect(detector.accuracy).to eq(0.5)
    end
  end

  describe '#sensitivity_label' do
    it 'returns a symbol' do
      expect(detector.sensitivity_label).to be_a(Symbol)
    end
  end

  describe '#bias_label' do
    it 'returns a symbol' do
      expect(detector.bias_label).to be_a(Symbol)
    end
  end

  describe '#adjust_criterion' do
    it 'shifts criterion by amount' do
      initial = detector.criterion
      detector.adjust_criterion(amount: 0.5)
      expect(detector.criterion).to eq(initial + 0.5)
    end

    it 'clamps at ceiling' do
      detector.adjust_criterion(amount: 10.0)
      expect(detector.criterion).to eq(Legion::Extensions::SignalDetection::Helpers::Constants::CRITERION_CEILING)
    end

    it 'clamps at floor' do
      detector.adjust_criterion(amount: -10.0)
      expect(detector.criterion).to eq(Legion::Extensions::SignalDetection::Helpers::Constants::CRITERION_FLOOR)
    end
  end

  describe '#to_h' do
    it 'returns a hash with expected keys' do
      result = detector.to_h
      expect(result).to include(:id, :domain, :sensitivity, :criterion, :hits, :misses,
                                :false_alarms, :correct_rejections, :trial_count,
                                :hit_rate, :false_alarm_rate, :accuracy,
                                :sensitivity_label, :bias_label, :created_at)
    end
  end
end
