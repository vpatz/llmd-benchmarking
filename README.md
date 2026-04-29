# llmd-benchmarking

Repo for deployment and benchmarking llm-d on a cluster with heterogeneous GPUs.

## Experiments

Each **Experiment** cell links to that deployment's directory (for example, [`4.1`](4.1/README.md) opens that experiment's README).

| Experiment | Category | Target hardware | Deployment shape |
| --- | --- | --- | --- |
| [`1.1`](1.1/README.md) | Default Kubernetes routing (baseline) | NVIDIA GPU | 2 vLLM instances, tensor parallelism 2 |
| [`1.2`](1.2/README.md) | Default Kubernetes routing (baseline) | AMD GPU | 4 vLLM instances on AMD with 2 GPUs each  |
| [`1.3`](1.2/README.md) | Mix GPU (baseline) | NVIDIA & AMD GPU | 2 vLLM instances on NVIDIA with 2 GPUs each, 4 vLLM instances on AMD with 2 GPUs each  |

| [`2.1`](2.1/README.md) | Prefix-based routing (same GPU type) | NVIDIA GPU | 2 vLLM instances, tensor parallelism 2 |
| [`2.2`](2.1/README.md) | Prefix-based routing (same GPU type) | AMD GPU | 4 vLLM instances, tensor parallelism 2 |


| [`3.1`](3.1/README.md) | Prefill-decode disaggregated (same GPU type) | NVIDIA GPU | Prefill: 2 vLLM instances, 1 GPU each. Decode: 1 vLLM instance, 2 GPUs |
| [`4.1`](4.1/README.md) | Prefix-based routing (heterogeneous GPU types) | NVIDIA and AMD GPUs | 2 vLLM instances on NVIDIA with 2 GPUs each, 4 vLLM instances on AMD with 2 GPUs each |
| [`4.2`](4.2/README.md) | Prefix-based routing (heterogeneous GPU types) | NVIDIA, AMD, and Intel Gaudi GPUs | 2 vLLM instances on NVIDIA with 2 GPUs each, 4 vLLM instances on AMD with 2 GPUs each |

Reference workload target: prompt input tokens `10k`, output tokens `1k`.

## Evaluation using `guidellm`

GuideLLM deployment and benchmarking assets live under [`benchmarking/`](benchmarking/README.md).

Latest benchmark summary:
- [`benchmarking/summary.md`](benchmarking/summary.md)



Plots

1. Ex 1.1 + 3.1 (prefix aware + PD)

2. Ex 1.1 + 2.1

3. Ex 1.2 + 2.2 


Mix GPU
3. Ex 1.3  +  4.1

