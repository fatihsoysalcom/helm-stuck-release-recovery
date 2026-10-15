#!/bin/bash
set -euo pipefail

# --- Configuration ---
RELEASE_NAME="my-stuck-app"
CHART_NAME="oci://registry-1.docker.io/bitnamicharts/nginx"
CHART_VERSION="16.0.0" # Use a specific version for reproducibility

echo "--- Helm Stuck Release Troubleshooting Demo ---"
echo "This script demonstrates how to diagnose and fix a Helm release stuck in a failed state."
echo "It requires Helm and kubectl to be installed and configured to a Kubernetes cluster."
echo ""

# --- Prerequisites Check ---
if ! command -v helm &> /dev/null; then
    echo "Error: Helm CLI not found. Please install Helm."
    exit 1
fi
if ! command -v kubectl &> /dev/null; then
    echo "Error: kubectl CLI not found. Please install kubectl."
    exit 1
fi
echo "Helm and kubectl found. Proceeding..."
echo ""

# --- Initial Cleanup ---
echo "1. Initial Cleanup: Ensuring no existing release with name '$RELEASE_NAME'."
helm uninstall "$RELEASE_NAME" &> /dev/null || true
kubectl delete all -l "app.kubernetes.io/instance=$RELEASE_NAME" &> /dev/null || true
sleep 2 # Give Kubernetes some time to clean up
echo "Cleanup complete."
echo ""

# --- Step 1: Initial Successful Install ---
echo "2. Initial Install: Deploying '$CHART_NAME' successfully."
echo "helm install $RELEASE_NAME $CHART_NAME --version $CHART_VERSION --wait --timeout 2m"
helm install "$RELEASE_NAME" "$CHART_NAME" --version "$CHART_VERSION" --wait --timeout 2m
echo "Initial install complete. Status:"
helm list -f "$RELEASE_NAME"
helm history "$RELEASE_NAME"
# Store the revision number of the successful install for potential rollback
SUCCESSFUL_REVISION=$(helm history "$RELEASE_NAME" | grep "$RELEASE_NAME" | awk '$2 == "1" {print $2}')
echo "Successful install revision: $SUCCESSFUL_REVISION"
echo ""

# --- Step 2: Simulate a Failed Upgrade ---
echo "3. Simulating a Failed Upgrade: Attempting to upgrade with a non-existent image tag."
echo "This will leave the release in a 'FAILED' state, preventing further operations."
# We expect this command to fail, so we temporarily disable exit on error and check the exit code
set +e 
helm upgrade "$RELEASE_NAME" "$CHART_NAME" --version "$CHART_VERSION" --set image.tag=nonexistent-tag --wait --timeout 1m
UPGRADE_EXIT_CODE=$?
set -e # Re-enable exit on error

if [ $UPGRADE_EXIT_CODE -ne 0 ]; then
    echo "Upgrade command failed as expected. The release should now be in a 'FAILED' state."
else
    echo "Warning: Upgrade command did not fail. This might indicate an issue with the simulation."
fi
echo "Current Helm release status after failed upgrade attempt:"
helm list -f "$RELEASE_NAME" # This should show FAILED, illustrating the problem
helm history "$RELEASE_NAME" # This should show a new FAILED revision
echo ""

# --- Step 3: Diagnose the Problem ---
echo "4. Diagnosing the Problem: Checking release status and Kubernetes resources."
echo "   - 'helm list' shows the release is FAILED."
echo "   - 'helm history' shows the failed revision."
echo "   - 'helm status' provides detailed information about the last attempt."
echo "   - 'kubectl get all -l app.kubernetes.io/instance=$RELEASE_NAME' shows underlying K8s resources."

echo "--- helm status $RELEASE_NAME ---"
helm status "$RELEASE_NAME" || true # status might fail if release is truly broken, but usually works
echo ""

echo "--- kubectl get all -l app.kubernetes.io/instance=$RELEASE_NAME ---"
kubectl get all -l "app.kubernetes.io/instance=$RELEASE_NAME"
echo ""

# Find the name of the problematic pod to describe it
POD_NAME=$(kubectl get pods -l "app.kubernetes.io/instance=$RELEASE_NAME" -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || true)
if [ -n "$POD_NAME" ]; then
    echo "--- kubectl describe pod $POD_NAME ---"
    kubectl describe pod "$POD_NAME" # Useful for debugging pod-level issues
    echo ""
else
    echo "No pods found for '$RELEASE_NAME' to describe. This might happen if the deployment never started."
    echo ""
fi

# --- Step 4: Solution - Rollback to a Working Revision ---
echo "5. Solution Option A: Rolling back to the last known good revision ($SUCCESSFUL_REVISION)."
echo "This is often the safest first step if a previous working state exists."
echo "helm rollback $RELEASE_NAME $SUCCESSFUL_REVISION"
helm rollback "$RELEASE_NAME" "$SUCCESSFUL_REVISION"
echo "Rollback initiated. Checking status:"
helm list -f "$RELEASE_NAME" # Should now be DEPLOYED after successful rollback
helm history "$RELEASE_NAME" # Should show a new rolled-back revision
echo ""

echo "Verifying application status after rollback..."
helm status "$RELEASE_NAME"
echo ""

# --- Step 5: Solution - Uninstall (Alternative/Cleanup) ---
echo "6. Solution Option B: Uninstalling the release (if rollback is not possible or desired)."
echo "This completely removes the Helm release and its associated Kubernetes resources."
echo "helm uninstall $RELEASE_NAME"
helm uninstall "$RELEASE_NAME"
echo "Uninstall initiated. Checking status:"
helm list -f "$RELEASE_NAME" # Should show nothing for this release, indicating removal
echo ""

echo "Verifying Kubernetes resources are removed after uninstall..."
echo "kubectl get all -l app.kubernetes.io/instance=$RELEASE_NAME"
kubectl get all -l "app.kubernetes.io/instance=$RELEASE_NAME"
echo "If no resources are listed above, cleanup was successful."
echo ""

echo "--- Demo Complete ---"
echo "The script demonstrated how to simulate a failed Helm upgrade, diagnose the problem,"
echo "and resolve it using 'helm rollback' or 'helm uninstall'."
