#!/bin/bash

# 设置错误处理: 遇到错误时退出并显示错误信息
set -e

# 检查用户是否为 root
if [ "$EUID" -ne 0 ]; then
  echo "请使用 sudo 或 root 用户运行该脚本"
  exit 1
fi

echo "正在停止 OpenVPN 服务..."
sudo systemctl stop openvpn@server || echo "OpenVPN 服务未运行或不存在"

echo "正在卸载 OpenVPN..."
sudo apt-get remove --purge -y openvpn easy-rsa || echo "OpenVPN 或 Easy-RSA 未安装"

echo "删除残留的 OpenVPN 文件..."
[ -d /etc/openvpn ] && sudo rm -rf /etc/openvpn
[ -d /usr/share/easy-rsa ] && sudo rm -rf /usr/share/easy-rsa
[ -f /var/log/openvpn.log ] && sudo rm -f /var/log/openvpn.log

echo "删除 root 目录下的 OpenVPN 相关文件..."
[ -d /root/openvpn-ca ] && sudo rm -rf /root/openvpn-ca

echo "清理防火墙规则..."
# 假设网段为 10.8.0.0/24，删除相关的 iptables 规则
sudo iptables -t nat -D POSTROUTING -s 10.8.0.0/24 -o eth0 -j MASQUERADE || echo "未找到相关的 iptables 规则"

# 清除所有 POSTROUTING 规则中包含 10.8.0.0/24 的规则
sudo iptables -t nat -S POSTROUTING | grep -q "10.8.0.0/24" && sudo iptables -t nat -F POSTROUTING

# 禁用 IP 转发
echo "禁用 IP 转发..."
sudo sysctl -w net.ipv4.ip_forward=0

# 如果在 /etc/sysctl.conf 中启用了 IP 转发，删除该行
sudo sed -i '/net.ipv4.ip_forward=1/d' /etc/sysctl.conf

sudo apt autoremove -y

echo "清理完成"
