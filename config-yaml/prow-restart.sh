namespace=prow
deploys="minio crier deck ghproxy hook horologium prow-controller-manager sinker statusreconciler tide"
for i in $deploys;do kubectl -n $namespace rollout restart deploy $i;done