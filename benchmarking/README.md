# GuideLLM benchmarking

Namespace: **`varun-benchmark`** (your isolated project; inference may still run in **`vinod`** — the Job calls it via cluster DNS).

Based on this [article](https://developers.redhat.com/articles/2025/12/24/how-deploy-and-benchmark-vllm-guidellm-kubernetes#step_2__run_guidellm_as_a_kubernetes_job).

## One-shot apply

```bash
cd benchmarking
chmod +x apply.sh
# Create gateway token (namespaced to Varun’s resources — does not touch vinod Secrets)
oc create secret generic guidellm-gateway-token-varun -n varun-benchmark \
  --from-literal=token="$(oc whoami -t)"
./apply.sh
```

If `namespace.yaml` fails (permissions), use: **`oc new-project varun-benchmark`** then apply PVC + Job only.

## PVC `oc apply` fails (`Unauthorized` / `Forbidden`)

**Cause A — You are not an admin of `varun-benchmark`:** creating a **Namespace** with YAML does **not** run OpenShift’s **project** bootstrap, so you may have **no RoleBinding** to create PVCs there.

**Fix (pick one):**

1. **Cluster admin** grants you edit/admin on the namespace:

   ```bash
   oc adm policy add-role-to-user admin "$(oc whoami)" -n varun-benchmark
   ```

2. **Or** delete the bare namespace (needs someone with delete rights) and recreate as a **project** (you become admin):

   ```bash
   oc delete project varun-benchmark
   oc new-project varun-benchmark
   ```

3. **Confirm** you can create PVCs:

   ```bash
   oc auth can-i create persistentvolumeclaims -n varun-benchmark
   ```

   Must print **`yes`**.

**Cause B — Wrong StorageClass** (different error, often `Provisioning` / admission): list classes and align with your admin.

```bash
oc get storageclass
```

Then either keep `guidellm-pvc.yaml` or apply **`guidellm-pvc-default-sc.yaml`** (uses default provisioner).

## Manual steps

```bash
# 1. Namespace (if not using apply.sh)
oc apply -f namespace.yaml

# 2. Storage for benchmark output
oc apply -f guidellm-pvc.yaml

# 3. Secret (required before Job)
oc create secret generic guidellm-gateway-token-varun -n varun-benchmark \
  --from-literal=token="$(oc whoami -t)"

# 4. Job
oc apply -f guidellm-job.yaml

# 5. After job completes — helper pod to copy results
oc apply -f pvc-inspector-pod.yaml

# 6. Copy results (note -n varun-benchmark)
oc cp -n varun-benchmark pvc-inspector-varun:/mnt/results/benchmark-results.json ./benchmark-results.json
oc cp -n varun-benchmark pvc-inspector-varun:/mnt/results/benchmark-results.html ./benchmark-results.html
```

## Cross-namespace inference

The Job `--target` points at **`qwen2-7b-instruct-nvidia-epp-service.vinod.svc.cluster.local`** (serving in **`vinod`**). If traffic is blocked, ask your admin about **NetworkPolicy** egress from **`varun-benchmark`** to **`vinod`**.

## Local re-export

```bash
guidellm benchmark from-file ./benchmark-results.json
```
