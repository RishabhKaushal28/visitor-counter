# Cost Analysis (Before / After)

Fill the **Measured** columns from `cost-measurements.txt` (produced by `scripts/06-cost-measure.sh`)
and `docker images`. The "Expected" column is a rough guide only; replace it with your real numbers.

## Assumptions

- CPU: $0.04 per vCPU-hour; memory: $0.005 per GB-hour; 730 hours/month.
- Cost is computed from **requested** resources (what a cloud provider reserves and bills for).
- "Idle" means no load, with the HPA settled.

## Techniques

| # | Technique | Before | After |
|---|-----------|--------|-------|
| 1 | Image size reduction | `python:3.12` single stage | multi-stage `python:3.12-alpine`, non-root |
| 2 | Right-sizing | requests 500m CPU / 512Mi, limits 1 CPU / 1Gi | requests 100m / 64Mi, limits 250m / 128Mi |
| 3 | Autoscaling | fixed 6 replicas | HPA min 2 / max 6 (2 when idle) |
| 4 | Redis memory cap | unbounded | `maxmemory 64mb`, LRU |

## Results

| Metric | Before (measured) | After (measured) | Saving | Expected |
|--------|-------------------|------------------|--------|----------|
| Image size | 1630 MB | 87.5 MB | 94.6 % | ~1 GB -> ~60-80 MB |
| Idle web pods | 6 | 2 | 67 % | 6 -> 2 |
| CPU requested per pod | 500m | 100m | 80 % | |
| Memory requested per pod | 512Mi | 64Mi | 87.5 % | |
| Total CPU requested (idle) | 3000m | 200m | 93 % | |
| Total memory requested (idle) | 3072Mi | 128Mi | 96 % | |
| Actual CPU used (idle, `kubectl top`) | 6 m | 3 m | 50% | |
| Estimated cost / hour | $0.135 | $0.0086 | 93.6 % | ~$0.135 -> ~$0.009 |
| Estimated cost / month | $98.55 | $6.30 | 93.6 % | ~$98.6 -> ~$6.3 |

The Total and cost rows follow from the per-pod values and the assumptions above
(for example before: 6 x 0.5 vCPU x $0.04 + 6 x 0.5 GB x $0.005 = $0.135/hr).

## Conclusion

Smaller images pull and start faster and use less registry/storage; right-sizing stops reserving
unused capacity; the HPA keeps only 2 pods at idle and scales to 6 under load, so cost follows demand
while the service stays available.
