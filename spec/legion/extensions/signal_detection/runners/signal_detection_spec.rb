# frozen_string_literal: true

require 'legion/extensions/signal_detection/client'

RSpec.describe Legion::Extensions::SignalDetection::Runners::SignalDetection do
  let(:client) { Legion::Extensions::SignalDetection::Client.new }

  describe '#create_detector' do
    it 'creates a detector and returns id' do
      result = client.create_detector(domain: :threat)
      expect(result[:created]).to be true
      expect(result[:detector_id]).to match(/\A[0-9a-f-]{36}\z/)
      expect(result[:domain]).to eq(:threat)
    end
  end

  describe '#record_detection_trial' do
    it 'records a hit' do
      id = client.create_detector(domain: :test)[:detector_id]
      result = client.record_detection_trial(detector_id: id, signal_present: true, responded_present: true)
      expect(result[:outcome]).to eq(:hit)
      expect(result[:trial_count]).to eq(1)
    end

    it 'records a miss' do
      id = client.create_detector(domain: :test)[:detector_id]
      result = client.record_detection_trial(detector_id: id, signal_present: true, responded_present: false)
      expect(result[:outcome]).to eq(:miss)
    end

    it 'records a false alarm' do
      id = client.create_detector(domain: :test)[:detector_id]
      result = client.record_detection_trial(detector_id: id, signal_present: false, responded_present: true)
      expect(result[:outcome]).to eq(:false_alarm)
    end

    it 'records a correct rejection' do
      id = client.create_detector(domain: :test)[:detector_id]
      result = client.record_detection_trial(detector_id: id, signal_present: false, responded_present: false)
      expect(result[:outcome]).to eq(:correct_rejection)
    end

    it 'returns not_found for unknown detector' do
      result = client.record_detection_trial(detector_id: 'nonexistent', signal_present: true, responded_present: true)
      expect(result[:reason]).to eq(:not_found)
    end
  end

  describe '#compute_detector_sensitivity' do
    let(:detector_id) do
      id = client.create_detector(domain: :test)[:detector_id]
      8.times { client.record_detection_trial(detector_id: id, signal_present: true, responded_present: true) }
      2.times { client.record_detection_trial(detector_id: id, signal_present: false, responded_present: true) }
      id
    end

    it 'returns d_prime and criterion' do
      result = client.compute_detector_sensitivity(detector_id: detector_id)
      expect(result).to include(:d_prime, :criterion, :accuracy)
    end

    it 'returns sensitivity_label' do
      result = client.compute_detector_sensitivity(detector_id: detector_id)
      expect(result[:sensitivity_label]).to be_a(Symbol)
    end

    it 'returns not_found for unknown detector' do
      result = client.compute_detector_sensitivity(detector_id: 'unknown')
      expect(result[:found]).to be false
    end
  end

  describe '#adjust_detector_bias' do
    it 'shifts the criterion' do
      id = client.create_detector(domain: :test)[:detector_id]
      result = client.adjust_detector_bias(detector_id: id, amount: 0.5)
      expect(result[:criterion]).to be > 0.0
      expect(result[:bias_label]).to be_a(Symbol)
    end

    it 'returns not_found for unknown detector' do
      result = client.adjust_detector_bias(detector_id: 'none', amount: 0.1)
      expect(result[:adjusted]).to be false
    end
  end

  describe '#best_detectors' do
    it 'returns list sorted by sensitivity' do
      client.create_detector(domain: :A)
      client.create_detector(domain: :B)
      result = client.best_detectors(limit: 2)
      expect(result[:count]).to eq(2)
      expect(result[:detectors]).to be_an(Array)
    end
  end

  describe '#domain_detectors' do
    it 'filters by domain' do
      client.create_detector(domain: :audio)
      client.create_detector(domain: :audio)
      client.create_detector(domain: :visual)
      result = client.domain_detectors(domain: :audio)
      expect(result[:count]).to eq(2)
      expect(result[:domain]).to eq(:audio)
    end
  end

  describe '#optimal_detector_criterion' do
    it 'returns optimal criterion for balanced prior' do
      id = client.create_detector(domain: :test)[:detector_id]
      result = client.optimal_detector_criterion(detector_id: id, signal_probability: 0.5)
      expect(result[:optimal_criterion]).to be_within(0.001).of(0.0)
    end

    it 'returns not_found for unknown detector' do
      result = client.optimal_detector_criterion(detector_id: 'none')
      expect(result[:found]).to be false
    end
  end

  describe '#detector_roc_point' do
    it 'returns hit_rate and false_alarm_rate' do
      id = client.create_detector(domain: :test)[:detector_id]
      result = client.detector_roc_point(detector_id: id)
      expect(result).to include(:hit_rate, :false_alarm_rate, :d_prime)
    end

    it 'returns not_found for unknown detector' do
      result = client.detector_roc_point(detector_id: 'none')
      expect(result[:found]).to be false
    end
  end

  describe '#update_signal_detection' do
    it 'runs decay cycle' do
      id = client.create_detector(domain: :test)[:detector_id]
      client.record_detection_trial(detector_id: id, signal_present: true, responded_present: true)
      result = client.update_signal_detection
      expect(result).to include(:decayed)
    end
  end

  describe '#signal_detection_stats' do
    it 'returns total_detectors and top_detectors' do
      2.times { |i| client.create_detector(domain: :"d#{i}") }
      result = client.signal_detection_stats
      expect(result[:total_detectors]).to eq(2)
      expect(result[:top_detectors]).to be_an(Array)
    end
  end
end
