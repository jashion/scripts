#!/bin/bash
# shadowsocksR/SSR CentOS 7/8一键安装教程
# Author: hijk<https://www.hijk.pw>

echo "#############################################################"
echo "#         CentOS 7/8 ShadowsocksR/SSR 一键安装脚本          #"
echo "# 网址: https://www.hijk.pw                                 #"
echo "# 作者: hijk                                                #"
echo "#############################################################"
echo ""

red='\033[0;31m'
plain='\033[0m'

FILENAME="ShadowsocksR-v3.2.2"
URL="https://github.com/shadowsocksrr/shadowsocksr/archive/3.2.2.tar.gz"
BASE=`pwd`

function checkSystem()
{
    result=$(id | awk '{print $1}')
    if [ $result != "uid=0(root)" ]; then
        echo "请以root身份执行该脚本"
        exit 1
    fi

    if [ ! -f /etc/centos-release ];then
        echo "系统不是CentOS"
        exit 1
    fi
    
    result=`cat /etc/centos-release|grep -oE "[0-9.]+"`
    main=${result%%.*}
    if [ $main -lt 7 ]; then
        echo "不受支持的CentOS版本"
        exit 1
    fi
}

function getData()
{
    read -p "请设置SSR的密码（不输入则随机生成）:" password
    [ -z "$password" ] && password=`cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 16 | head -n 1`
    echo ""
    echo "密码： $password"
    echo ""
    
    while true
    do
        read -p "请设置SSR的端口号[1-65535]:" port
        [ -z "$port" ] && port="12345"
        expr $port + 0 &>/dev/null
        if [ $? -eq 0 ]; then
            if [ $port -ge 1 ] && [ $port -le 65535 ]; then
                echo ""
                echo "端口号： $port"
                echo ""
                break
            else
                echo "输入错误，端口号为1-65535的数字"
            fi
        else
            echo "输入错误，端口号为1-65535的数字"
        fi
    done
    echo "请选择SSR的加密方式:" 
    echo "1)aes-256-cfb"
    echo "2)aes-192-cfb"
    echo "3)aes-128-cfb"
    echo "4)aes-256-ctr"
    echo "5)aes-192-ctr"
    echo "6)aes-128-ctr"
    echo "7)aes-256-cfb8"
    echo "8)aes-192-cfb8"
    echo "9)aes-128-cfb8"
    echo "10)camellia-128-cfb"
    echo "11)camellia-192-cfb"
    echo "12)camellia-256-cfb"
    echo "13)chacha20-ietf"
    read -p "请选择加密方式（默认aes-256-cfb）" answer
    if [ -z "$answer" ]; then
        method="aes-256-cfb"
    else
        case $answer in
        1)
            method="aes-256-cfb"
            ;;
        2)
            method="aes-192-cfb"
            ;;
        3)
            method="aes-128-cfb"
            ;;
        4)
            method="aes-256-ctr"
            ;;
        5)
            method="aes-192-ctr"
            ;;
        6)
            method="aes-128-ctr"
            ;;
        7)
            method="aes-256-cfb8"
            ;;
        8)
            method="aes-192-cfb8"
            ;;
        9)
            method="aes-128-cfb8"
            ;;
        10)
            method="camellia-128-cfb"
            ;;
        11)
            method="camellia-192-cfb"
            ;;
        12)
            method="camellia-256-cfb"
            ;;
        13)
            method="chacha20-ietf"
            ;;
        *)
            echo "无效的选择，使用默认加密方式"
            method="aes-256-cfb"
        esac
    fi
    echo ""
    echo "加密方式： $method"
    echo ""

    echo "请选择SSR的协议："
    echo "1)origin"
    echo "2)verify_deflate"
    echo "3)auth_sha1_v4"
    echo "4)auth_aes128_md5"
    echo "5)auth_aes128_sha1"
    echo "6)auth_chain_a"
    echo "7)auth_chain_b"
    echo "8)auth_chain_c"
    echo "9)auth_chain_d"
    echo "10)auth_chain_e"
    echo "11)auth_chain_f"
    read -p "请选择加密方式（默认origin）" answer
    if [ -z "$answer" ]; then
        protocol="origin"
    else
        case $answer in
        1)
            protocol="origin"
            ;;
        2)
            protocol="verify_deflate"
            ;;
        3)
            protocol="auth_sha1_v4"
            ;;
        4)
            protocol="auth_aes128_md5"
            ;;
        5)
            protocol="auth_aes128_sha1"
            ;;
        6)
            protocol="auth_chain_a"
            ;;
        7)
            protocol="auth_chain_b"
            ;;
        8)
            protocol="auth_chain_c"
            ;;
        9)
            protocol="auth_chain_d"
            ;;
        10)
            protocol="auth_chain_e"
            ;;
        11)
            protocol="auth_chain_f"
            ;;
        *)
            echo "无效的选择，使用默认协议"
            protocol="origin"
        esac
    fi
    echo ""
    echo "协议： $protocol"
    echo ""


    echo "请选择SSR混淆模式："
    echo "1)plain"
    echo "2)http_simple"
    echo "3)http_post"
    echo "4)tls1.2_ticket_auth"
    echo "5)tls1.2_ticket_fastauth"
    read -p "请选择混淆模式（默认plain）" answer
    if [ -z "$answer" ]; then
        obfs="plain"
    else
        case $answer in
        1)
            obfs="plain"
            ;;
        2)
            obfs="http_simple"
            ;;
        3)
            obfs="http_post"
            ;;
        4)
            obfs="tls1.2_ticket_auth"
            ;;
        5)
            obfs="tls1.2_ticket_fastauth"
            ;;
        *)
            echo "无效的选择，使用默认混淆模式"
            obfs="plain"
        esac
    fi
    echo ""
    echo "混淆： $obfs"
    echo ""
}

function preinstall()
{
    sed -i 's/#ClientAliveInterval 0/ClientAliveInterval 60/' /etc/ssh/sshd_config
    systemctl restart sshd
    ret=`nginx -t`
    if [ "$?" != "0" ]; then
        echo "更新系统..."
        yum update -y
    fi
    echo "安装必要软件"
    yum install -y epel-release telnet curl wget vim net-tools libsodium openssl unzip
    if [ $main -eq 8 ]; then
        ln -s /usr/bin/python3 /usr/bin/python
    fi
    yum install -y nginx
    systemctl enable nginx && systemctl restart nginx

    if [ -s /etc/selinux/config ] && grep 'SELINUX=enforcing' /etc/selinux/config; then
        sed -i 's/SELINUX=enforcing/SELINUX=permissive/g' /etc/selinux/config
        setenforce 0
    fi
}

function installSSR()
{
    echo 下载安装文件
    if ! wget --no-check-certificate -O ${FILENAME}.tar.gz ${URL}; then
        echo -e "[${red}Error${plain}] 下载文件失败!"
        exit 1
    fi

    tar -zxf ${FILENAME}.tar.gz
    mv shadowsocksr-3.2.2/shadowsocks /usr/local
    if [ ! -f /usr/local/shadowsocks/server.py ]; then
        echo "安装失败，请到 https://www.hijk.pw 网站反馈"
        cd ${BASE} && rm -rf shadowsocksr-3.2.2 ${FILENAME}.tar.gz
        exit 1
    fi

     cat > /etc/shadowsocksR.json<<-EOF
{
    "server":"0.0.0.0",
    "server_ipv6":"[::]",
    "server_port":${port},
    "local_port":1080,
    "password":"${password}",
    "timeout":600,
    "method":"${method}",
    "protocol":"${protocol}",
    "protocol_param":"",
    "obfs":"${obfs}",
    "obfs_param":"",
    "redirect":"",
    "dns_ipv6":false,
    "fast_open":false,
    "workers":1
}
EOF

cat > /usr/lib/systemd/system/shadowsocksR.service <<-EOF
[Unit]
Description=shadowsocksR
Documentation=https://www.hijk.pw/
After=network-online.target
Wants=network-online.target

[Service]
Type=forking
LimitNOFILE=32768
ExecStart=/usr/local/shadowsocks/server.py -c /etc/shadowsocksR.json -d start
ExecReload=/bin/kill -s HUP $MAINPID
ExecStop=/bin/kill -s TERM $MAINPID

[Install]
WantedBy=multi-user.target
EOF

    systemctl daemon-reload
    systemctl enable shadowsocksR && systemctl restart shadowsocksR
}

function setFirewall()
{
    systemctl status firewalld > /dev/null 2>&1
    if [ $? -eq 0 ];then
        firewall-cmd --permanent --add-port=${port}/tcp
        firewall-cmd --permanent --add-port=${port}/udp
        firewall-cmd --permanent --add-service=http
        firewall-cmd --reload
    fi
}

function installBBR()
{
    result=$(lsmod | grep bbr)
    if [ "$result" != "" ]; then
        echo BBR模块已安装
        echo "3" > /proc/sys/net/ipv4/tcp_fastopen
        echo "net.ipv4.tcp_fastopen = 3" >> /etc/sysctl.conf
        bbr=true
        return
    fi
    
    if [ $main -eq 8 ]; then
        echo "tcp_bbr" >> /etc/modules-load.d/modules.conf
        echo "net.core.default_qdisc=fq" >> /etc/sysctl.conf
        echo "net.ipv4.tcp_congestion_control=bbr" >> /etc/sysctl.conf
        sysctl -p
        bbr=true
        return
    fi

    echo 安装BBR模块...
    rpm --import https://www.elrepo.org/RPM-GPG-KEY-elrepo.org
    rpm -Uvh http://www.elrepo.org/elrepo-release-7.0-4.el7.elrepo.noarch.rpm
    yum --enablerepo=elrepo-kernel install kernel-ml -y
    yum remove kernel-3.* -y
    grub2-set-default 0
    echo "tcp_bbr" >> /etc/modules-load.d/modules.conf
    echo "net.core.default_qdisc=fq" >> /etc/sysctl.conf
    echo "net.ipv4.tcp_congestion_control=bbr" >> /etc/sysctl.conf
    echo "3" > /proc/sys/net/ipv4/tcp_fastopen
    echo "net.ipv4.tcp_fastopen = 3" >> /etc/sysctl.conf
    bbr=false
}

function showTip()
{
    echo ============================================
    echo -e "          ${red}SSR安装成功！${plain}               "
    echo ""
    echo -e " IP(address):  ${red}`curl -s -4 icanhazip.com`${plain}"
    echo -e " 端口(port)：${red}${port}${plain}"
    echo -e " 密码(password)：${red}${password}${plain}"
    echo -e " 加密方式(method)： ${red}${method}${plain}"
    echo -e " 协议(protocol)：" ${red}${protocol}${plain}
    echo -e " 混淆(obfuscation)：" ${red}${obfs}${plain}
    echo    
    echo -e "SSR配置文件：${red}/etc/shadowsocksR.json${plain}，请按照自己需要进行修改"         
    echo  
    echo  如果连接不成功，请注意查看安全组/防火墙是否已放行端口
    echo 
    echo -e "如有其他问题，请到 ${red}https://www.hijk.pw${plain} 留言反馈"

    if [ "${bbr}" == "false" ]; then
        echo  
        echo  为使BBR模块生效，系统将在30秒后重启
        echo  
        echo  您可以按ctrl + c取消重启，稍后输入 reboot 重启系统
    fi
    echo ============================================

    if [ "${bbr}" == "false" ]; then
        sleep 30
        reboot
    fi
}

echo -n "系统版本:  "
cat /etc/centos-release

function install()
{
    checkSystem
    getData
    preinstall
    installBBR
    installSSR
    setFirewall

    showTip
    cd ${BASE} && rm -rf shadowsocksr-3.2.2 ${FILENAME}.tar.gz
}

function uninstall()
{
    read -p "您确定真的要卸载SSR吗？(y/n)" answer
    [ -z ${answer} ] && answer="n"

    if [ "${answer}" == "y" ] || [ "${answer}" == "Y" ]; then
        rm -f /etc/shadowsocksR.json
        rm -f /var/log/shadowsocks.log
        rm -rf /usr/local/shadowsocks
        systemctl disable shadowsocksR && systemctl stop shadowsocksR && rm -rf /usr/lib/systemd/system/shadowsocksR.service
    fi
    echo -e " ${red}卸载成功${plain}"
}

action=$1
[ -z $1 ] && action=install
case "$action" in
    install|uninstall)
        ${action}
        ;;
    *)
        echo "参数错误"
        echo "用法: `basename $0` [install|uninstall]"
        ;;
esac
