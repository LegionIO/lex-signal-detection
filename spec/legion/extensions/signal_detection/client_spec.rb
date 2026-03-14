# frozen_string_literal: true

require 'legion/extensions/signal_detection/client'

RSpec.describe Legion::Extensions::SignalDetection::Client do
  let(:client) { described_class.new }

  it 'responds to all runner methods' do
    expect(client).to respond_to(:create_detector)
    expect(client).to respond_to(:record_detection_trial)
    expect(client).to respond_to(:compute_detector_sensitivity)
    expect(client).to respond_to(:adjust_detector_bias)
    expect(client).to respond_to(:best_detectors)
    expect(client).to respond_to(:domain_detectors)
    expect(client).to respond_to(:optimal_detector_criterion)
    expect(client).to respond_to(:detector_roc_point)
    expect(client).to respond_to(:update_signal_detection)
    expect(client).to respond_to(:signal_detection_stats)
  end
end
