#!/bin/bash

# 创建 CA 目录并初始化 PKI
init(){
    echo "创建并初始化 PKI 目录..."
    # 检查 make-cadir 命令是否存在
    if ! command -v make-cadir &> /dev/null; then
        echo "make-cadir 未找到，手动创建目录..."
        mkdir -p ~/openvpn-ca || { echo "无法创建 CA 目录"; exit 1; }
    else
        make-cadir ~/openvpn-ca || { echo "无法创建 CA 目录"; exit 1; }
    fi
    cd ~/openvpn-ca
    ./easyrsa init-pki || { echo "初始化 PKI 失败"; exit 1; }
}

# 生成证书
generate(){
    # 生成 CA 证书
    echo "生成 CA 证书..."
    ./easyrsa --batch build-ca nopass || { echo "生成 CA 证书失败"; exit 1; }
    # 生成服务器证书并签署
    echo "生成服务器证书..."
    ./easyrsa --batch gen-req server nopass || { echo "生成服务器请求失败"; exit 1; }
    ./easyrsa --batch sign-req server server || { echo "签署服务器请求失败"; exit 1; }
    # 生成 Diffie-Hellman 参数
    echo "生成 Diffie-Hellman 参数..."
    ./easyrsa gen-dh || { echo "生成 Diffie-Hellman 参数失败"; exit 1; }
    # 生成 TLS 密钥
    cd /etc/openvpn/
    openvpn --genkey --secret ta.key || { echo "生成 TLS 密钥失败"; exit 1; }
}

# 复制生成的证书和密钥文件到 OpenVPN 目录
configure_user_certificate() {
    echo "复制证书和密钥..."
    sudo cp ~/openvpn-ca/pki/ca.crt /etc/openvpn/
    sudo cp ~/openvpn-ca/pki/dh.pem /etc/openvpn/
    echo "配置用户证书..."
    sudo cp ~/openvpn-ca/pki/issued/server.crt /etc/openvpn/
    sudo cp ~/openvpn-ca/pki/private/server.key /etc/openvpn/
}

# 创建 OpenVPN 配置文件和写入内容
generate_configuration_file() {
    echo "创建 OpenVPN 配置文件..."
    sudo touch /etc/openvpn/server.conf || { echo "创建配置文件失败"; exit 1; }

    echo "写入 OpenVPN server.conf 配置文件..."
    sudo sh -c 'cat << EOF > /etc/openvpn/server.conf
port 1194
proto udp
dev tun
ca ca.crt
cert server.crt
key server.key
dh dh.pem
tls-version-min 1.2
tls-groups prime256v1
tls-crypt ta.key
server 10.8.0.0 255.255.255.0
ifconfig-pool-persist ipp.txt
keepalive 10 120
cipher AES-128-GCM
persist-key
persist-tun
client-to-client
push "block-outside-dns"
push "redirect-gateway def1 bypass-dhcp"
push "dhcp-option DNS 8.8.8.8"
push "dhcp-option DNS 8.8.4.4"
log /var/log/openvpn.log
status /var/log/openvpn-status.log 10
management 127.0.0.1 5555
max-clients 10
verb 3
EOF'
}

# 设置错误处理: 发生错误时退出并提示信息
set -e

# 更新包列表并安装 OpenVPN 和 Easy-RSA
echo "更新系统包列表..."
sudo apt update

echo "安装 OpenVPN 和 Easy-RSA..."
sudo apt install openvpn easy-rsa -y

init
generate
configure_user_certificate
generate_configuration_file

# 检查日志文件权限
echo "设置日志文件权限..."
sudo touch /var/log/openvpn.log /var/log/openvpn-status.log
sudo chmod 644 /var/log/openvpn.log /var/log/openvpn-status.log

# 检查防火墙规则
echo "允许 1194 端口通过防火墙..."
sudo ufw allow 1194/udp || { echo "无法添加防火墙规则"; exit 1; }

# 启动 OpenVPN 服务器
echo "启动 OpenVPN 服务器..."
sudo systemctl restart openvpn@server || { echo "启动 OpenVPN 服务器失败"; exit 1; }

echo "OpenVPN 安装和配置完成。"

# 检查服务状态
echo "检查 OpenVPN 服务状态..."
sudo systemctl status openvpn@server
