# GuideLLM Benchmark Summary

## Scope

This summary captures the final validated benchmark run for the `Qwen/Qwen2.5-7B-Instruct` endpoint using GuideLLM on the OpenShift cluster.

## Test Setup

- Target model: `Qwen/Qwen2.5-7B-Instruct`
- Target endpoint: OpenAI-compatible gateway endpoint
- Profile type: `concurrent`
- Concurrency levels tested: `1` and `10`
- Max requests per concurrency level: `30`
- Max time per concurrency level: `180s`
- Prompt source: generated default prompt bank created at runtime
- Prompt pool size loaded: `100` unique prompts
- Output artifacts generated: `JSON`, `HTML`, `CSV`

## Validation Notes

- Prompt samples were verified to be non-empty and different from one another.
- The run did **not** use the earlier broken `Open-Platypus` mapping path.
- The benchmark completed successfully and produced all requested output files.

## Results

| Concurrency | Successful Requests | Errored Requests | Mean Requests/sec | Median Latency (s) | P95 Latency (s) | Median TTFT (ms) | P95 TTFT (ms) | Median ITL (ms) | Mean Output Tokens/sec | Mean Total Tokens/sec | Median Prompt Tokens | Median Output Tokens |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| 1 | 29 | 1 | 0.248 | 3.482 | 6.253 | 28.503 | 167.755 | 6.727 | 146.852 | 157.627 | 43 | 688 |
| 10 | 30 | 0 | 1.706 | 5.386 | 6.709 | 26.057 | 52.147 | 7.399 | 1031.575 | 1105.935 | 43 | 718 |

## Known Issue

- One request in the `concurrency=1` phase failed with `HTTP 500 Internal Server Error` from the `/v1/chat/completions` endpoint.
- Evidence from the benchmark artifact confirms this was a real server-side `500` and not a client-side timeout or prompt-formatting issue.
- The `concurrency=10` phase completed with `0` errors.

## Interpretation

- The prompt correctness issue from earlier runs is resolved for this final experiment.
- At `concurrency=10`, the system delivered materially higher request throughput and token throughput than at `concurrency=1`.
- Latency remained in a similar band at the median and p95 levels between the two tested concurrency points, though the `concurrency=1` phase showed one server-side failure and a much worse TTFT p95.

## Shareable Conclusion

The final benchmark run is valid for reporting with one caveat: the `concurrency=1` phase had a single server-side `500` error, while the `concurrency=10` phase completed cleanly. Aside from that error, the workload, prompts, and metric outputs were validated and the benchmark artifacts were generated successfully.
