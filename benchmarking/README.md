# GuideLLM benchmarking

Based on this [article.](https://developers.redhat.com/articles/2025/12/24/how-deploy-and-benchmark-vllm-guidellm-kubernetes#step_2__run_guidellm_as_a_kubernetes_job)

```bash

# 1. Create storage for bencharmking output
oc apply -f guidellm-pvc.yaml

# 2. Run the benchmarking job
oc apply -f guidellm-job.yaml

# 3. After job completes deploy helper pod
oc apply -f pvc-inspector-pod.yaml

# 4. Copy results 
oc cp pvc-inspector:/mnt/results/benchmark-results.json ./benchmark-results.json 
oc cp pvc-inspector:/mnt/results/benchmark-results.html ./benchmark-results.html 

# 5. Load benchmark-results.html in browser

# 6. Run guidellm from saved json
guidellm benchmark from-file ./benchmark-results.json


```