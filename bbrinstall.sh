#!/bin/bash

# 確認当前系统类型
if [ -f /etc/redhat-release ]; then
    # CentOS 系统
    OS="centos"
    yum update -y
    yum install -y kernel-devel kernel-headers wget
elif [ -f /etc/debian_version ]; then
    # Debian 或 Ubuntu 系统
    OS=$(lsb_release -si | tr '[:upper:]' '[:lower:]')
    apt-get update
    apt-get install -y build-essential wget
else
    echo "不支持该系统类型。"
    exit 1
fi

# 安装 TCP 優化参数
echo "net.core.default_qdisc=fq" >> /etc/sysctl.conf
echo "net.ipv4.tcp_congestion_control=bbr" >> /etc/sysctl.conf
echo "net.ipv4.tcp_timestamps=1" >> /etc/sysctl.conf
echo "net.ipv4.tcp_sack=1" >> /etc/sysctl.conf
echo "net.ipv4.tcp_window_scaling=1" >> /etc/sysctl.conf
echo "net.ipv4.tcp_rfc1337=1" >> /etc/sysctl.conf
echo "net.ipv4.tcp_fin_timeout=15" >> /etc/sysctl.conf
echo "net.ipv4.tcp_tw_reuse=1" >> /etc/sysctl.conf
echo "net.ipv4.tcp_tw_recycle=1" >> /etc/sysctl.conf
echo "net.ipv4.tcp_max_syn_backlog=8192" >> /etc/sysctl.conf
echo "net.ipv4.tcp_max_tw_buckets=2000000" >> /etc/sysctl.conf
echo "net.core.netdev_max_backlog=5000" >> /etc/sysctl.conf
echo "net.core.somaxconn=250000" >> /etc/sysctl.conf

# 询问是否开启 TCP 窗口缩放因子和接收窗口大小的自定义设置
echo "您是否需要自定义 TCP 窗口缩放因子和接收窗口大小？[Y/n]"
read need_opt

if [ "$need_opt" == "Y" ] || [ "$need_opt" == "y" ]; then
    # 配置 TCP 参数
    echo "请输入 TCP 窗口缩放因子（默认值为 10）："
    read wmem
    echo "请输入 TCP 接收窗口大小（默认值为 87380）："
    read rmem
    echo "请输入最大本地端口数（默认值为 65535）："
    read local_port_range

    echo "net.ipv4.tcp_mem=${wmem} ${wmem} ${wmem}" >> /etc/sysctl.conf
    echo "net.ipv4.tcp_rmem=${rmem} ${rmem} ${rmem}" >> /etc/sysctl.conf
    echo "net.ipv4.tcp_wmem=${wmem} ${wmem} ${wmem}" >> /etc/sysctl.conf
    echo "net.ipv4.ip_local_port_range=1024 ${local_port_range}" >> /etc/sysctl.conf

    echo "TCP 参数已经设置完成。"
fi

# 加载 TCP 参数
sysctl -p

# 安装 Centos 7 官方軟體庫中提供的最新版内核
yum update -y kernel
grub2-set-default 0

echo "Linux 内核已经安装成功，并且 TCP 参数已经开启。请重新启动系统以使设置生效。"
