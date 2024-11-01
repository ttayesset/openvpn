#!/bin/bash

# 检查是否为 root 用户
if [ "$EUID" -ne 0 ]; then
  echo "请使用 sudo 或 root 用户运行该脚本"
  exit 1
fi
sudo apt install dos2unix -y
chmod +x install_openvpn.sh create_user.sh traffic_forwarding.sh uninstall_openvpn.sh
dos2unix openvpn_control.sh install_openvpn.sh create_user.sh traffic_forwarding.sh uninstall_openvpn.sh
# 主菜单函数
main_menu() {
  echo "OpenVPN 管理脚本"
  echo "请选择一个选项:"
  echo "1) 安装 OpenVPN"
  echo "2) 创建 OpenVPN 用户"
  echo "3) 配置流量转发"
  echo "4) 卸载 OpenVPN"
  echo "5) 退出"
  read -rp "请输入选项 (1-5): " choice

  case $choice in
    1) install_openvpn ;;
    2) create_user ;;
    3) traffic_forwarding ;;
    4) uninstall_openvpn ;;
    5) exit 0 ;;
    *) echo "无效选项"; main_menu ;;
  esac
}

# 安装 OpenVPN 函数
install_openvpn() {
  echo "正在安装 OpenVPN..."
  ./install_openvpn.sh || echo "安装 OpenVPN 失败"
  main_menu
}

# 创建 OpenVPN 用户函数
create_user() {
  echo "请输入要创建的用户名:"
  read -r username
  if [ -z "$username" ]; then
    echo "用户名不能为空"
  else
    echo "正在创建用户 $username..."
    ./create_user.sh "$username" || echo "创建用户失败"
  fi
  main_menu
}

# 配置流量转发函数
traffic_forwarding() {
  echo "正在配置流量转发..."
  ./traffic_forwarding.sh || echo "流量转发配置失败"
  main_menu
}

# 卸载 OpenVPN 函数
uninstall_openvpn() {
  echo "正在卸载 OpenVPN..."
  ./uninstall_openvpn.sh || echo "卸载 OpenVPN 失败"
  main_menu
}

# 运行主菜单
main_menu
