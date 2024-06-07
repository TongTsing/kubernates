#!/bin/bash

yum remove docker
sudo yum install -y yum-utils
sudo yum-config-manager \
--add-repo \
http://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo
sudo yum install -y docker-ce-20.10.7 docker-ce-cli-20.10.7 containerd.io-1.4.6
systemctl enable docker --now
sudo mkdir -p /etc/docker
sudo tee /etc/docker/daemon.json <<EOF
{
  "registry-mirrors": ["https://soxxp5r5.mirror.aliyuncs.com"]
}
EOF
sudo systemctl daemon-reload
  sudo systemctl restart docker
# 将 SELinux 设置为 permissive 模式（相当于将其禁用）
sudo setenforce 0
# 永久禁用
sudo sed -i 's/^SELINUX=enforcing$/SELINUX=permissive/' /etc/selinux/config

# 关闭swap  临时
swapoff -a
# 永久
sed -ri 's/.*swap.*/#&/' /etc/fstab  

# 将桥接的IPv4流量传递到iptables的链 这个是k8s官网的步骤
cat > /etc/sysctl.d/k8s.conf << EOF
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
EOF

# 关闭防火墙
systemctl stop firewalld
systemctl disable firewalld

sysctl --system  # 生效
#配置k8s的yum源地址
cat <<EOF | sudo tee /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=http://mirrors.aliyun.com/kubernetes/yum/repos/kubernetes-el7-x86_64
enabled=1
gpgcheck=0
repo_gpgcheck=0
gpgkey=http://mirrors.aliyun.com/kubernetes/yum/doc/yum-key.gpg
   http://mirrors.aliyun.com/kubernetes/yum/doc/rpm-package-key.gpg
EOF

#安装 kubelet，kubeadm，kubectl
sudo yum install -y kubelet-1.20.9 kubeadm-1.20.9 kubectl-1.20.9

#启动kubelet
sudo systemctl enable --now kubelet

#所有机器配置master域名 ,修改hosts
echo "192.168.10.111  k8s-master" >> /etc/hosts
cat >> /etc/hosts << EOF
192.168.10.112   k8s-node2
192.168.10.113   k8s-node3
EOF
