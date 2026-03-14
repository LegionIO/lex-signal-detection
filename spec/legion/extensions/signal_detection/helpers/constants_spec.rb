# frozen_string_literal: true

RSpec.describe Legion::Extensions::SignalDetection::Helpers::Constants do
  describe '.sensitivity_label' do
    it 'labels exceptional for d_prime >= 3.0' do
      expect(described_class.sensitivity_label(3.5)).to eq(:exceptional)
    end

    it 'labels excellent for 2.0 <= d_prime < 3.0' do
      expect(described_class.sensitivity_label(2.5)).to eq(:excellent)
    end

    it 'labels good for 1.0 <= d_prime < 2.0' do
      expect(described_class.sensitivity_label(1.5)).to eq(:good)
    end

    it 'labels moderate for 0.5 <= d_prime < 1.0' do
      expect(described_class.sensitivity_label(0.7)).to eq(:moderate)
    end

    it 'labels poor for d_prime < 0.5' do
      expect(described_class.sensitivity_label(0.2)).to eq(:poor)
    end
  end

  describe '.bias_label' do
    it 'labels very_conservative for criterion >= 1.0' do
      expect(described_class.bias_label(1.5)).to eq(:very_conservative)
    end

    it 'labels conservative for 0.3 <= criterion < 1.0' do
      expect(described_class.bias_label(0.5)).to eq(:conservative)
    end

    it 'labels neutral for -0.3 <= criterion < 0.3' do
      expect(described_class.bias_label(0.0)).to eq(:neutral)
    end

    it 'labels liberal for -1.0 <= criterion < -0.3' do
      expect(described_class.bias_label(-0.5)).to eq(:liberal)
    end

    it 'labels very_liberal for criterion < -1.0' do
      expect(described_class.bias_label(-1.5)).to eq(:very_liberal)
    end
  end

  describe '.clamp_sensitivity' do
    it 'clamps to floor' do
      expect(described_class.clamp_sensitivity(-1.0)).to eq(0.0)
    end

    it 'clamps to ceiling' do
      expect(described_class.clamp_sensitivity(10.0)).to eq(5.0)
    end

    it 'passes through valid values' do
      expect(described_class.clamp_sensitivity(2.5)).to eq(2.5)
    end
  end

  describe '.clamp_criterion' do
    it 'clamps to floor' do
      expect(described_class.clamp_criterion(-5.0)).to eq(-3.0)
    end

    it 'clamps to ceiling' do
      expect(described_class.clamp_criterion(5.0)).to eq(3.0)
    end

    it 'passes through valid values' do
      expect(described_class.clamp_criterion(1.0)).to eq(1.0)
    end
  end

  describe 'TRIAL_OUTCOMES' do
    it 'includes all four outcomes' do
      expect(described_class::TRIAL_OUTCOMES).to include(:hit, :miss, :false_alarm, :correct_rejection)
    end

    it 'is frozen' do
      expect(described_class::TRIAL_OUTCOMES).to be_frozen
    end
  end
end
