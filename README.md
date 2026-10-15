# Helm Stuck Release Recovery

This example demonstrates how to diagnose and recover from a Helm release that is stuck in a failed state after an incomplete deployment or upgrade. It simulates a failed upgrade by using a non-existent image tag, then shows how to use `helm list`, `helm history`, `helm status`, and `kubectl` to identify the problem. Finally, it illustrates solutions like `helm rollback` to a previous working revision or `helm uninstall` for complete removal and cleanup.

## Language

`bash`

## How to Run

1. Ensure you have Helm CLI and kubectl installed and configured to access a Kubernetes cluster.
2. Save the code as `fix_helm_release.sh`.
3. Make the script executable: `chmod +x fix_helm_release.sh`.
4. Run the script: `./fix_helm_release.sh`.

## Original Article

This example accompanies the Turkish article: [Helm'de Yarım Kalan Bir Deploy Sonrası Tüm Release'lerin Reddedilmesi Sorunu](https://fatihsoysal.com/blog/helmde-yarim-kalan-bir-deploy-sonrasi-tum-releaselerin-reddedilmesi-sorunu/).

## License

MIT — see [LICENSE](LICENSE).
