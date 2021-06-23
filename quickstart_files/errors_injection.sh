#!/bin/sh

inject_unschedulable_pods_anomaly() {
    cat <<EOF | KUBECONFIG="${KUBECONFIG:-/etc/rancher/rke2/rke2.yaml}" PATH="${PATH:+${PATH}:}/var/lib/rancher/rke2/bin/" kubectl apply -f -
    apiVersion: batch/v1
    kind: Job
    metadata:
      name: test-job-unschedulable
      labels:
        is-opni-demo: "true"
    spec:
      completions: 10
      parallelism: 10
      template:
        spec:
          containers:
            - name: test
              image: busybox
              command:
              - /bin/ls
          affinity:
            nodeAffinity:
              requiredDuringSchedulingIgnoredDuringExecution:
                nodeSelectorTerms:
                - matchExpressions:
                  - key: nonexistent
                    operator: Exists
          restartPolicy: Never
EOF
}

inject_nonexistent_image_pods_anomaly() {
    cat <<EOF | KUBECONFIG="${KUBECONFIG:-/etc/rancher/rke2/rke2.yaml}" PATH="${PATH:+${PATH}:}/var/lib/rancher/rke2/bin/" kubectl apply -f -
    apiVersion: batch/v1
    kind: Job
    metadata:
      name: test-job-nonexistent-image
      labels:
        is-opni-demo: "true"
    spec:
      completions: 10
      parallelism: 10
      template:
        spec:
          containers:
            - name: test
              image: this-image-does-not-exist
              command:
              - /test
              imagePullPolicy: Always
          restartPolicy: Never
EOF
}

inject_nonzero_exit_code_pods_anomaly() {
    cat <<EOF | KUBECONFIG="${KUBECONFIG:-/etc/rancher/rke2/rke2.yaml}" PATH="${PATH:+${PATH}:}/var/lib/rancher/rke2/bin/" kubectl apply -f -
    apiVersion: batch/v1
    kind: Job
    metadata:
      name: test-job-nonzero-exit-code
      labels:
        is-opni-demo: "true"
    spec:
      completions: 10
      parallelism: 10
      template:
        spec:
          containers:
            - name: test
              image: busybox
              command:
              - /bin/false
          restartPolicy: Never
EOF
}

undo_anomalies() {
  KUBECONFIG="${KUBECONFIG:-/etc/rancher/rke2/rke2.yaml}" PATH="${PATH:+${PATH}:}/var/lib/rancher/rke2/bin/" kubectl delete jobs -l is-opni-demo=true
}

get_user_anomaly_input() {
  while true
  do
  	echo " Possible Anomalies to inject"
  	echo "1) Create 10 unschedulable pods."
  	echo "2) Create 10 pods with nonexistent images."
  	echo "3) Create 10 pods that will exit with non-zero exit codes."
    echo "u) Undo anomalies injected into cluster."
    echo "q) Exit this script."
  	read -p "Type the number of the anomaly you would like to inject: " anomaly
  	if [ "$anomaly" = '1' ]; then
  		echo "Injecting the fault to create 10 unschedulable pods."
  		inject_unschedulable_pods_anomaly
  	elif [ "$anomaly" = '2' ]; then
  		echo "Injecting the fault to create 10 pods with nonexistent images."
  		inject_nonexistent_image_pods_anomaly
  	elif [ "$anomaly" = '3' ]; then
  		echo "Injecting the fault to create 10 pods that will exit with non-zero exit codes."
  		inject_nonzero_exit_code_pods_anomaly
    elif [ "$anomaly" = 'u' ]; then
      echo "Undoing anomalies injected into systems."
      undo_anomalies
    elif [ "$anomaly" = 'q' ]; then
      break
    fi
  done
}
get_user_anomaly_input
exit 0
