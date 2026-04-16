# llmd-benchmarking
Repo for deployment and benchmarking llm-d on cluster with heterogeneous GPUs.


# Deployment variations

* llmd using default K8s routing (baseline)
  
  * Deploy on NVIDIA GPU
  * Deploy on AMD GPU
  
* llmd with prefix-based routing on same GPU type
  * Deploy on NVIDIA GPU
  * Deploy on AMD GPU

* llmd with prefill-decode disaggregated inference on same GPU type
  * Deploy on NVIDIA GPU
    
* llmd with pref-based routing on hetereogeneous GPU types
  * Deploy on NVIDIA, AMD GPUs
  * Deploy on NVIDIA, AMD, Intel Gaudi GPUs
 
