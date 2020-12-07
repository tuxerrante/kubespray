#!/bin/bash
# ======================================================
#   kubespray first startup on a test machine          =
# ======================================================

# git clone https://github.com/kubernetes-sigs/kubespray.git
# cd kubespray || exit 1
git checkout expert

# Install dependencies from ``requirements.txt``
# sudo yum install -y ansible-2.9.15 python-jinja2 python-netaddr
sudo pip3 install -r requirements.txt

# Copy ``inventory/sample`` as ``inventory/expert_cluster``
cp -rfp inventory/expert inventory/expert_cluster

# Update Ansible inventory file with inventory builder
# declare -a IPS=(10.10.1.3 10.10.1.4 10.10.1.5)
my_ip=$(hostname -i)
declare -a IPS="($my_ip)"

CONFIG_FILE=inventory/expert_cluster/hosts.yaml python3 contrib/inventory_builder/inventory.py "${IPS[@]}"

# Review and change parameters under ``inventory/expert_cluster/group_vars``
# cat inventory/expert_cluster/group_vars/all/all.yml
# cat inventory/expert_cluster/group_vars/k8s-cluster/k8s-cluster.yml

# Enable containerd runtime
if ! sudo systemctl status containerd 1>/dev/null; then 
    sudo yum install -y yum-utils device-mapper-persistent-data lvm2
    sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
    sudo yum update -y && sudo yum install -y containerd.io
    sudo mkdir -p /etc/containerd
    sudo containerd config default | tee /etc/containerd/config.toml
fi

# Deploy Kubespray with Ansible Playbook - run the playbook as root
# The option `--become` is required, as for example writing SSL keys in /etc/,
# installing packages and interacting with various systemd daemons.
# Without --become the playbook will fail to run!
ansible-playbook -i inventory/expert_cluster/hosts.yaml  --become --become-user=root cluster.yml

mkdir -p "$HOME/.kube"
sudo cp -f -i /etc/kubernetes/admin.conf "$HOME/.kube/config"
sudo chown "$(id -u):$(id -g)" "$HOME/.kube/config"
