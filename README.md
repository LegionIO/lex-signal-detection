# lex-signal-detection

Signal Detection Theory (SDT) implementation for LegionIO cognitive agents. Tracks hits, misses, false alarms, and correct rejections per detector to compute d-prime sensitivity and response bias (criterion).

## What It Does

`lex-signal-detection` gives cognitive agents a formal model of their ability to distinguish real signals from noise. For each named detector, it tracks trial outcomes and computes:

- **d-prime**: sensitivity — how well signal is separated from noise (higher = better detection)
- **Criterion**: response bias — positive = conservative (miss-prone), negative = liberal (false-alarm-prone)
- **Hit rate / False alarm rate**: Laplace-smoothed proportions for numerical stability
- **Accuracy**: overall fraction of correct classifications
- **ROC point**: `(false_alarm_rate, hit_rate)` for receiver operating characteristic analysis
- **Optimal criterion**: Bayesian estimate derived from prior trial distribution

The criterion drifts toward 0 (neutral) each tick, modeling the tendency to re-center bias when information is sparse.

## Usage

```ruby
require 'legion/extensions/signal_detection'

client = Legion::Extensions::SignalDetection::Client.new

# Create a detector
result = client.create_detector(name: 'anomaly_detector', domain: :monitoring)
detector_id = result[:detector_id]

# Record outcomes (signal_present: was there really a signal? responded_present: did agent say yes?)
client.record_detection_trial(detector_id: detector_id, signal_present: true,  responded_present: true)  # hit
client.record_detection_trial(detector_id: detector_id, signal_present: false, responded_present: false) # correct rejection
client.record_detection_trial(detector_id: detector_id, signal_present: true,  responded_present: false) # miss
client.record_detection_trial(detector_id: detector_id, signal_present: false, responded_present: true)  # false alarm

# Compute sensitivity
client.compute_detector_sensitivity(detector_id: detector_id)
# => { sensitivity: 1.2, label: 'good' }

# Adjust bias (positive = more conservative, negative = more liberal)
client.adjust_detector_bias(detector_id: detector_id, amount: 0.1)

# Get Bayesian optimal criterion
client.optimal_detector_criterion(detector_id: detector_id)
# => { optimal_criterion: -0.15 }

# ROC point
client.detector_roc_point(detector_id: detector_id)
# => { hit_rate: 0.67, false_alarm_rate: 0.33 }

# Best detectors by sensitivity
client.best_detectors(limit: 5)

# Per-tick decay (criteria drift toward neutral)
client.update_signal_detection
```

## Development

```bash
bundle install
bundle exec rspec
bundle exec rubocop
```

## License

MIT
