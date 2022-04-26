curl -skSL https://raw.githubusercontent.com/kubernetes-csi/csi-driver-nfs/master/deploy/install-driver.sh | bash -s master --

kubectl -n kube-system get pod -o wide -l app=csi-nfs-controller

kubectl -n kube-system get pod -o wide -l app=csi-nfs-node

cat <<EOF
EOF | kubectl create -f -
apiVersion: storage.k8s.io/v1beta1
kind: CSIDriver
metadata:
  name: nfs.csi.k8s.io
spec:
  attachRequired: false
  volumeLifecycleModes:
    - Persistent
  fsGroupPolicy: File
EOF
EOF
