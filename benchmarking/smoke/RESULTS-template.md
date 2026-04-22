# Smoke test run log (fill in as you execute each leg)

| Leg | Phase | Result | Notes |
|-----|-------|--------|-------|
| 1 | S01 GitHub HTML template URL | | |
| 2 | S02 Hugging Face Hub | | |
| 3 | S03–S04 `SMOKE_TARGET` + normalize | | |
| 4 | S05 GET /health | | |
| 5 | S06 GET /v1/models | | |
| 6 | S07 POST /v1/chat/completions | | |

Run from `benchmarking/smoke` after `source smoke.env`:

```bash
./run-all.sh
```

Or egress-only:

```bash
SMOKE_SKIP="S03 S04 S05 S06 S07" ./run-all.sh
```
