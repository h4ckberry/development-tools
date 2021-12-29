#!/bin/sh
KUBE_VERSION=$1 
MASTER01=$(kubectl get node | grep master | awk '{print $1}')
WORKER01=$(kubectl get node --no-headers | grep -v master | awk '{print $1}' | grep 01)
WORKER02=$(kubectl get node --no-headers | grep -v master | awk '{print $1}' | grep 02)
WORKERS=($WORKER01 $WORKER02)

echo "\n--- Before update ---"
kubectl get node

# master node
echo "\n###############################"
echo "### $MASTER01 node update start ###"
echo "###############################"
ssh $MASTER01 "sudo apt update -y"
# バージョン確認
echo "\n--- Check current version ---"
ssh $MASTER01 "apt list --installed | grep -e kubeadm -e kubelet -e kubectl"
# アップデートしたいバージョンがあるか確認
echo "\n--- Check target version ---"
ssh $MASTER01 "sudo apt-cache madison kubeadm kubectl kubelet | grep $KUBE_VERSION"
# バージョンが固定されているか確認
echo "\n--- Check hold version ---"
ssh $MASTER01 "sudo apt-mark showhold"
# kubeadmアップデート
echo "\n--- Update kubeadm pkag ---"
ssh $MASTER01 "sudo apt-get update && sudo apt-get install -y --allow-change-held-packages kubeadm=$KUBE_VERSION"
echo "\n--- Hold version ---"
ssh $MASTER01 "sudo apt-mark hold kubeadm"
# kubeadmバージョン確認
echo "\n--- Check kubeadm version ---"
ssh $MASTER01 "kubeadm version"
# マスターノードkubeadmアップグレード
echo "\n--- Update kubeadm ---"
ssh $MASTER01 "kubeadm upgrade plan"
ssh $MASTER01 "sudo kubeadm upgrade plan"
ssh $MASTER01 "sudo kubeadm upgrade apply $KUBE_VERSION"
echo "\n--- Successful upgrade of kubeadm !!! ---\n"

echo "\n--- Drain $MASTER01 ---"
kubectl drain $MASTER01 --ignore-daemonsets

echo "\n--- Update kubelet & kubectl pakg ---"
ssh $MASTER01 "sudo apt-get update && sudo apt-get install -y --allow-change-held-packages kubelet=$KUBE_VERSION kubectl=$KUBE_VERSION"
echo "\n--- Hold version ---"
ssh $MASTER01 "sudo apt-mark hold kubelet kubectl"
echo "\n--- Restart kubelet ---"
ssh $MASTER01 "sudo systemctl daemon-reload"
ssh $MASTER01 "sudo systemctl restart kubelet"

echo "\n--- Uncordon $MASTER01 ---"
kubectl uncordon $MASTER01
echo "\n--- Check kubectl version ---"
ssh $MASTER01 "kubectl version"
echo "\nMaster node update done !!!"

# woker node
for WORKER in ${WORKERS[@]}
do
    echo "\n###############################"
    echo "### $WORKER node update start ###"
    echo "###############################"
    ssh $WORKER "sudo apt update -y"
    # バージョン確認
    echo "\n--- Check current version ---"
    ssh $WORKER "apt list --installed | grep -e kubeadm -e kubelet -e kubectl"
    # アップデートしたいバージョンがあるか確認
    echo "\n--- Check target version ---"
    ssh $WORKER "sudo apt-cache madison kubeadm kubectl kubelet | grep $KUBE_VERSION"
    # バージョンが固定されているか確認
    echo "\n--- Check hold version ---"
    ssh $WORKER "sudo apt-mark showhold"
    # kubeadmアップデート
    echo "\n--- Update kubeadm pkag ---"
    ssh $WORKER "sudo apt-get update && sudo apt-get install -y --allow-change-held-packages kubeadm=$KUBE_VERSION"
    echo "\n--- Hold version ---"
    ssh $WORKER "sudo apt-mark hold kubeadm"
    # kubeadmバージョン確認
    echo "\n--- Check kubeadm version ---"
    ssh $WORKER "kubeadm version"
    # マスターノードkubeadmアップグレード
    echo "\n--- Update kubeadm ---"
    ssh $WORKER "sudo kubeadm upgrade node"
    echo "\n--- Successful upgrade of kubeadm !!! ---\n"

    echo "\n--- Drain $WORKER ---"
    kubectl drain $WORKER --ignore-daemonsets --delete-emptydir-data

    echo "\n--- Update kubelet & kubectl pakg ---"
    ssh $WORKER "sudo apt-get update && sudo apt-get install -y --allow-change-held-packages kubelet=$KUBE_VERSION kubectl=$KUBE_VERSION"
    echo "\n--- Hold version ---"
    ssh $WORKER "sudo apt-mark hold kubelet kubectl"
    echo "\n--- Restart kubelet ---"
    ssh $WORKER "sudo systemctl daemon-reload"
    ssh $WORKER "sudo systemctl restart kubelet"

    echo "\n--- Uncordon $WORKER ---"
    kubectl uncordon $WORKER
    echo "\n--- Check kubectl version ---"
    ssh $WORKER "kubeadm version && kubectl version"
    echo "$WORKER node update done"
done

kubectl get node

echo "\nAll complete"