# lex-signal-detection

**Level 3 Leaf Documentation**
- **Parent**: `/Users/miverso2/rubymine/legion/extensions-agentic/CLAUDE.md`
- **Gem**: `lex-signal-detection`
- **Version**: `0.1.0`
- **Namespace**: `Legion::Extensions::SignalDetection`

## Purpose

Implements Signal Detection Theory (SDT) for cognitive agents. Tracks hits, misses, false alarms, and correct rejections per detector, then computes d-prime (sensitivity) and criterion (response bias). Supports bias adjustment and Bayesian optimal criterion calculation. Models the agent's ability to distinguish real signals from noise in a given domain.

## Gem Info

- **Gem name**: `lex-signal-detection`
- **License**: MIT
- **Ruby**: >= 3.4
- **No runtime dependencies** beyond the Legion framework

## File Structure

```
lib/legion/extensions/signal_detection/
  version.rb                           # VERSION = '0.1.0'
  helpers/
    constants.rb                       # limits, sensitivity bounds, criterion bounds, labels
    detector.rb                        # Detector class — SDT metrics per detector
    detection_engine.rb                # DetectionEngine class — collection of detectors
  runners/
    signal_detection.rb                # Runners::SignalDetection module — all public runner methods
  client.rb                            # Client class including Runners::SignalDetection
```

## Key Constants

| Constant | Value | Purpose |
|---|---|---|
| `MAX_DETECTORS` | 100 | Maximum detectors |
| `MAX_TRIALS` | 1000 | Maximum trial records per detector (ring buffer) |
| `DEFAULT_SENSITIVITY` | 1.0 | Initial d-prime-equivalent sensitivity |
| `SENSITIVITY_FLOOR` | 0 | Minimum sensitivity |
| `SENSITIVITY_CEILING` | 5.0 | Maximum sensitivity |
| `DEFAULT_CRITERION` | 0.0 | Initial criterion (unbiased) |
| `CRITERION_FLOOR` | -3.0 | Most liberal criterion (say yes to everything) |
| `CRITERION_CEILING` | 3.0 | Most conservative criterion (say yes to nothing) |
| `LEARNING_RATE` | 0.05 | Sensitivity update step |
| `DECAY_RATE` | 0.01 | Per-tick criterion drift toward 0 |
| `TRIAL_OUTCOMES` | 4 symbols | `:hit`, `:miss`, `:false_alarm`, `:correct_rejection` |
| `SENSITIVITY_LABELS` | hash | Named tiers from `chance` to `excellent` |
| `BIAS_LABELS` | hash | Named bias states: `liberal`, `neutral`, `conservative` |

## Helpers

### `Helpers::Detector`

Single SDT detector with trial outcome tracking.

- `initialize(id:, name:, domain: :general, sensitivity: DEFAULT_SENSITIVITY, criterion: DEFAULT_CRITERION)` — hit=0, miss=0, false_alarm=0, correct_rejection=0, trials=[]
- `record_trial(outcome:)` — increments the matching counter (hit/miss/false_alarm/correct_rejection); appends timestamped record to trials ring buffer (max MAX_TRIALS)
- `hit_rate` — Laplace-smoothed: `(hit + 0.5) / (hit + miss + 1)`
- `false_alarm_rate` — Laplace-smoothed: `(false_alarm + 0.5) / (false_alarm + correct_rejection + 1)`
- `compute_dprime` — `z_score(hit_rate) - z_score(false_alarm_rate)`; returns `sensitivity`
- `compute_criterion` — `-0.5 * (z_score(hit_rate) + z_score(false_alarm_rate))`
- `z_score(p)` — inverse normal CDF using Winitzki erfinv approximation
- `adjust_criterion(amount)` — increments criterion, clamps to floor/ceiling
- `accuracy` — `(hit + correct_rejection).to_f / [total_trials, 1].max`

### `Helpers::DetectionEngine`

Collection of Detector objects with bulk query operations.

- `initialize` — empty detectors hash
- `create_detector(name:, domain: :general)` — returns nil if at MAX_DETECTORS
- `record_trial(detector_id:, signal_present:, responded_present:)` — classifies outcome from booleans (true/true=hit, true/false=miss, false/true=false_alarm, false/false=correct_rejection), then calls `detector.record_trial`
- `compute_sensitivity(detector_id)` — returns updated d-prime from `detector.compute_dprime`
- `adjust_bias(detector_id:, amount:)` — calls `detector.adjust_criterion`
- `best_detectors(limit: 5)` — sorted by sensitivity descending
- `by_domain(domain)` — filter detectors by domain
- `optimal_criterion(detector_id)` — Bayesian optimal: `0.5 * Math.log(prior_noise / prior_signal)` using class priors derived from trial history
- `roc_point(detector_id)` — returns `{ hit_rate:, false_alarm_rate: }` for ROC curve plotting
- `decay_all` — all criteria drift toward 0 by DECAY_RATE

## Runners

All runners are in `Runners::SignalDetection`. The `Client` includes this module and owns a `DetectionEngine` instance.

| Runner | Parameters | Returns |
|---|---|---|
| `create_detector` | `name:, domain: :general` | `{ success:, detector_id:, name:, domain: }` |
| `record_detection_trial` | `detector_id:, signal_present:, responded_present:` | `{ success:, detector_id:, outcome:, accuracy: }` |
| `compute_detector_sensitivity` | `detector_id:` | `{ success:, detector_id:, sensitivity:, label: }` |
| `adjust_detector_bias` | `detector_id:, amount:` | `{ success:, detector_id:, criterion: }` |
| `best_detectors` | `limit: 5` | `{ success:, detectors:, count: }` |
| `domain_detectors` | `domain:` | `{ success:, detectors:, count: }` |
| `optimal_detector_criterion` | `detector_id:` | `{ success:, detector_id:, optimal_criterion: }` |
| `detector_roc_point` | `detector_id:` | `{ success:, detector_id:, hit_rate:, false_alarm_rate: }` |
| `update_signal_detection` | (none) | `{ success:, detectors: }` — calls `decay_all` |
| `signal_detection_stats` | (none) | Engine summary with total detectors, best sensitivity, mean accuracy |

## Integration Points

- **lex-tick / lex-cortex**: `update_signal_detection` wired as a tick handler performs criterion decay each cycle; `record_detection_trial` is called after each sensing event
- **lex-sensory-gating**: sensory gating controls whether a stimulus is processed at all; signal detection models the accuracy of classifying stimuli that do pass through
- **lex-prediction**: prediction outcomes (hit vs miss) pair naturally with signal detection trial recording
- **lex-surprise**: surprise magnitude can inform bias adjustment — high surprise suggests current criterion is miscalibrated

## Development Notes

- Laplace smoothing on hit_rate and false_alarm_rate prevents d-prime from exploding to infinity when hit_rate=1.0 or false_alarm_rate=0.0
- `z_score` uses the Winitzki approximation for the inverse error function: `erf_inv(p) = sign(p-0.5) * sqrt(sqrt((2/pi/a + ln(1-x2)/2)^2 - ln(1-x2)/a) - (2/pi/a + ln(1-x2)/2))` where `a = 0.147`
- `compute_dprime` updates `sensitivity` attribute on the detector; subsequent calls to `sensitivity` return the last computed value
- `decay_all` drifts criteria toward 0 (neutral) — this models criterion re-centering when no recent trials exist
- `optimal_criterion` uses trial-derived priors; with few trials the estimate is noisy, which is intentional (matches SDT theory for small samples)
