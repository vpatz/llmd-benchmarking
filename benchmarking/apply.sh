#!/usr/bin/env bash
# Apply Varun's benchmarking resources (isolated names in varun-benchmark — does not create objects in vinod).
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
NS="varun-benchmark"
SECRET="guidellm-gateway-token-varun"

echo "==> Namespace ${NS}"
oc apply -f "${ROOT}/namespace.yaml"

echo "==> PVC guidellm-results-pvc-varun"
oc apply -f "${ROOT}/guidellm-pvc.yaml"

echo ""
echo "==> Secret ${SECRET} (required once)"
echo "    oc create secret generic ${SECRET} -n ${NS} --from-literal=token=\"\$(oc whoami -t)\""
echo ""

if ! oc get secret "${SECRET}" -n "${NS}" &>/dev/null; then
  echo "Secret ${SECRET} not found — create it, then re-run this script."
  echo "  oc create secret generic ${SECRET} -n ${NS} --from-literal=token=\"\$(oc whoami -t)\""
  exit 1
fi

echo "==> Job guidellm-benchmark-job-varun"
oc apply -f "${ROOT}/guidellm-job.yaml"

echo ""
echo "Watch: oc get jobs,pods -n ${NS} -w"
echo "Logs:  oc logs -n ${NS} job/guidellm-benchmark-job-varun --tail=200 -f"
