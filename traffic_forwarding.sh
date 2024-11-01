#!/bin/bash

# 启用 IP 转发
echo "启用 IP 转发..."
sudo sysctl -w net.ipv4.ip_forward=1 || { echo "启用 IP 转发失败"; exit 1; }

# 永久启用 IP 转发
if ! grep -q "net.ipv4.ip_forward=1" /etc/sysctl.conf; then
    echo "将 IP 转发设置添加到 /etc/sysctl.conf 以便永久生效..."
    echo "net.ipv4.ip_forward=1" | sudo tee -a /etc/sysctl.conf
else
    echo "IP 转发已在 /etc/sysctl.conf 中永久启用"
fi
sudo sysctl -p

# 获取当前的网络接口名称
interface=$(ip route | grep default | awk '{print $5}')
echo "检测到的网络接口: $interface"

# 配置 NAT 转发
echo "配置 NAT 转发..."
sudo iptables -t nat -A POSTROUTING -s 10.8.0.0/24 -o "$interface" -j MASQUERADE || { echo "配置 NAT 转发失败"; exit 1; }

# 检查并创建 /etc/iptables 目录
if [ ! -d /etc/iptables ]; then
    echo "创建 /etc/iptables 目录..."
    sudo mkdir -p /etc/iptables
fi

# 持久化 NAT 转发规则
if ! command -v iptables-save &> /dev/null; then
    echo "安装 iptables-persistent 以确保 NAT 规则持久化..."
    sudo apt update
    sudo apt install -y iptables-persistent
fi

echo "保存 NAT 转发规则..."
sudo sh -c 'iptables-save > /etc/iptables/rules.v4'

# 启动 OpenVPN 服务器
echo "启动 OpenVPN 服务器..."
sudo systemctl restart openvpn@server || { echo "启动 OpenVPN 服务器失败"; exit 1; }

echo "OpenVPN 服务器已启动，所有配置已完成。"
