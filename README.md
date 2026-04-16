# llmd-benchmarking
Repo for deployment and benchmarking llm-d on cluster with heterogeneous GPUs.


# Deployment directories

* llmd using default K8s routing (baseline)
  * Deploy on NVIDIA GPU (1.1)
  * Deploy on AMD GPU (1.2)
  
* llmd with prefix-based routing on same GPU type
  * Deploy on NVIDIA GPU (2.1)
  * Deploy on AMD GPU (2.2)

* llmd with prefill-decode disaggregated inference on same GPU type
  * Deploy on NVIDIA GPU (3.1)
    
* llmd with pref-based routing on hetereogeneous GPU types
  * Deploy on NVIDIA, AMD GPUs (4.1)
  * Deploy on NVIDIA, AMD, Intel Gaudi GPUs (4.2) 
 
