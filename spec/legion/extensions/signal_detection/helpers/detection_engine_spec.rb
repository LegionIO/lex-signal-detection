# frozen_string_literal: true

RSpec.describe Legion::Extensions::SignalDetection::Helpers::DetectionEngine do
  subject(:engine) { described_class.new }

  let(:detector_id) { engine.create_detector(domain: :vision).id }

  describe '#create_detector' do
    it 'creates a detector and returns it' do
      detector = engine.create_detector(domain: :auditory)
      expect(detector).to be_a(Legion::Extensions::SignalDetection::Helpers::Detector)
    end

    it 'increments count' do
      engine.create_detector(domain: :auditory)
      engine.create_detector(domain: :visual)
      expect(engine.count).to eq(2)
    end

    it 'raises when max detectors reached' do
      stub_const('Legion::Extensions::SignalDetection::Helpers::Constants::MAX_DETECTORS', 1)
      engine.create_detector(domain: :test)
      expect { engine.create_detector(domain: :overflow) }.to raise_error(ArgumentError, /max detectors/)
    end
  end

  describe '#record_trial' do
    it 'records a hit when signal present and responded present' do
      result = engine.record_trial(detector_id: detector_id, signal_present: true, responded_present: true)
      expect(result[:outcome]).to eq(:hit)
    end

    it 'records a miss when signal present and not responded' do
      result = engine.record_trial(detector_id: detector_id, signal_present: true, responded_present: false)
      expect(result[:outcome]).to eq(:miss)
    end

    it 'records a false alarm when no signal and responded present' do
      result = engine.record_trial(detector_id: detector_id, signal_present: false, responded_present: true)
      expect(result[:outcome]).to eq(:false_alarm)
    end

    it 'records a correct rejection when no signal and not responded' do
      result = engine.record_trial(detector_id: detector_id, signal_present: false, responded_present: false)
      expect(result[:outcome]).to eq(:correct_rejection)
    end

    it 'raises KeyError for unknown detector' do
      expect do
        engine.record_trial(detector_id: 'bogus', signal_present: true, responded_present: true)
      end.to raise_error(KeyError)
    end
  end

  describe '#compute_sensitivity' do
    it 'returns d_prime, criterion, accuracy' do
      5.times { engine.record_trial(detector_id: detector_id, signal_present: true, responded_present: true) }
      2.times { engine.record_trial(detector_id: detector_id, signal_present: false, responded_present: false) }
      result = engine.compute_sensitivity(detector_id: detector_id)
      expect(result).to include(:d_prime, :criterion, :accuracy, :hit_rate, :false_alarm_rate)
    end

    it 'raises KeyError for unknown detector' do
      expect { engine.compute_sensitivity(detector_id: 'unknown') }.to raise_error(KeyError)
    end
  end

  describe '#adjust_bias' do
    it 'shifts the criterion' do
      before = engine.get(detector_id).criterion
      engine.adjust_bias(detector_id: detector_id, amount: 0.5)
      expect(engine.get(detector_id).criterion).to be > before
    end
  end

  describe '#best_detectors' do
    it 'returns detectors sorted by sensitivity' do
      id1 = engine.create_detector(domain: :A).id
      id2 = engine.create_detector(domain: :B).id
      10.times { engine.record_trial(detector_id: id1, signal_present: true, responded_present: true) }
      engine.record_trial(detector_id: id1, signal_present: false, responded_present: true)
      2.times  { engine.record_trial(detector_id: id2, signal_present: true, responded_present: true) }
      10.times { engine.record_trial(detector_id: id2, signal_present: false, responded_present: true) }
      result = engine.best_detectors(limit: 2)
      expect(result.first[:sensitivity]).to be >= result.last[:sensitivity]
    end

    it 'respects limit' do
      3.times { |i| engine.create_detector(domain: :"d#{i}") }
      expect(engine.best_detectors(limit: 2).size).to eq(2)
    end
  end

  describe '#by_domain' do
    it 'filters by domain' do
      engine.create_detector(domain: :audio)
      engine.create_detector(domain: :audio)
      engine.create_detector(domain: :visual)
      result = engine.by_domain(domain: :audio)
      expect(result.size).to eq(2)
      expect(result.all? { |d| d[:domain] == :audio }).to be true
    end
  end

  describe '#optimal_criterion' do
    it 'returns optimal criterion for balanced prior' do
      result = engine.optimal_criterion(detector_id: detector_id, signal_probability: 0.5)
      expect(result[:optimal_criterion]).to be_within(0.001).of(0.0)
    end

    it 'returns positive criterion for low signal probability' do
      result = engine.optimal_criterion(detector_id: detector_id, signal_probability: 0.2)
      expect(result[:optimal_criterion]).to be > 0
    end
  end

  describe '#roc_point' do
    it 'returns hit_rate and false_alarm_rate' do
      result = engine.roc_point(detector_id: detector_id)
      expect(result).to include(:hit_rate, :false_alarm_rate, :d_prime)
    end
  end

  describe '#decay_all' do
    it 'returns count of detectors updated' do
      engine.record_trial(detector_id: detector_id, signal_present: true, responded_present: true)
      count = engine.decay_all
      expect(count).to eq(1)
    end

    it 'skips detectors with no trials' do
      count = engine.decay_all
      expect(count).to eq(0)
    end
  end

  describe '#to_h' do
    it 'returns detector count and map' do
      result = engine.to_h
      expect(result).to include(:detector_count, :detectors)
    end
  end
end
