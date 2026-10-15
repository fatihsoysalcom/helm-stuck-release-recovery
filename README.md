# helm-stuck-release-recovery
This example demonstrates how to diagnose and recover from a Helm release that is stuck in a failed state after an incomplete deployment or upgrade. It simulates a failed upgrade by using a non-existent image tag, then shows how to use `helm list`, `helm history`, `helm status`, and `kubectl` to identify the problem. Finally, it illustrates solutio
