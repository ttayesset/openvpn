#!/bin/bash

# 定义客户端名称
CLIENT_NAME=$1

# 确保提供客户端名称
if [ -z "$CLIENT_NAME" ]; then
    echo "请提供客户端名称"
    exit 1
fi

# 定位到 openvpn-ca 目录
cd ~/openvpn-ca

# 生成客户端证书并签署
echo "生成客户端证书..."
./easyrsa --batch --req-cn=$CLIENT_NAME gen-req $CLIENT_NAME nopass || { echo "生成客户端请求失败"; exit 1; }
./easyrsa --batch sign-req client $CLIENT_NAME || { echo "签署客户端请求失败"; exit 1; }

# 获取公网 IP 地址
SERVER_IP=$(curl -s ifconfig.me)
if [ -z "$SERVER_IP" ]; then
    echo "无法获取公网 IP，请检查网络连接。"
    exit 1
fi

# 创建客户端的 .ovpn 文件
cat > ~/$CLIENT_NAME.ovpn <<EOF
client
dev tun
proto udp
remote $SERVER_IP 1194
resolv-retry infinite
nobind
persist-key
persist-tun

cipher AES-128-GCM
remote-cert-tls server
tls-version-min 1.2
auth SHA256
key-direction 1
verb 3

<ca>
$(cat /etc/openvpn/ca.crt)
</ca>

<cert>
$(openssl x509 -in ~/openvpn-ca/pki/issued/$CLIENT_NAME.crt -outform PEM)
</cert>

<key>
$(cat ~/openvpn-ca/pki/private/$CLIENT_NAME.key)
</key>

<tls-crypt>
$(cat /etc/openvpn/ta.key)
</tls-crypt>
EOF

echo "$CLIENT_NAME 的 .ovpn 文件已生成在 ~/$CLIENT_NAME.ovpn"
