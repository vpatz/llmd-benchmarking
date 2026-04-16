# llmd-benchmarking

Repo for deployment and benchmarking llm-d on a cluster with heterogeneous GPUs.

## Experiments

Each **Experiment** cell links to that deployment’s directory ([`4.1`](4.1/README.md) opens the experiment README).

| Experiment | Category | Target hardware |
| --- | --- | --- |
| [`1.1`](1.1/README.md) | Default Kubernetes routing (baseline) | NVIDIA GPU |
| [`1.2`](1.2/README.md) | Default Kubernetes routing (baseline) | AMD GPU |
| [`2.1`](2.1/README.md) | Prefix-based routing (same GPU type) | NVIDIA GPU |
| [`2.2`](2.2/README.md) | Prefix-based routing (same GPU type) | AMD GPU |
| [`3.1`](3.1/README.md) | Prefill–decode disaggregated (same GPU type) | NVIDIA GPU |
| [`4.1`](4.1/README.md) | Prefix-based routing (heterogeneous GPU types) | NVIDIA and AMD GPUs |
| [`4.2`](4.2/README.md) | Prefix-based routing (heterogeneous GPU types) | NVIDIA, AMD, and Intel Gaudi GPUs |


## Evaluation using `guidellm`