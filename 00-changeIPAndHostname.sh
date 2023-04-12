#!/bin/bash

#=========================================================
# ===============一键设置前置环境=========================
# ===============Author: SummerLv=========================
# ===============CreateDate: 2023年4月12日================
#=========================================================
# 注意在root用户下执行此脚本或者在非root用户下使用此命令执行此脚本 su - root -s 此脚本所在绝对路径


# [linux的shell脚本判断当前是否为root用户](https://blog.csdn.net/wzy_1988/article/details/8470890)
if [ `whoami` != "root" ];then
	echo "非root用户！请切换到root用户执行此脚本！"
	exit 1
fi


#=============================变量定义区========================
ifcfg_ens33_file=/etc/sysconfig/network-scripts/ifcfg-ens33
hostname_file=/etc/hostname
hosts_file=/etc/hosts
sudoers_file=/etc/sudoers
ipAddr=$1
ipPrefix=${ipAddr%.*}
ipSuffix=${ipAddr##*.}
hostnamePrefix=hadoop
ip1=$[$ipSuffix+1]
ip2=$[$ipSuffix+2]
userToAdd=lv
softwares=(epel-release net-tools vim psmisc  nc  rsync  lrzsz  ntp libzstd openssl-static tree iotop git)


# [Shell脚本判断IP是否合法性（多种方法）](https://blog.51cto.com/lizhenliang/1736160)
function check_ip() {
    IP=$1
    VALID_CHECK=$(echo $IP|awk -F. '$1<=255&&$2<=255&&$3<=255&&$4<=255{print "yes"}')
    if echo $IP|grep -E "^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$">/dev/null; then
        if [ ${VALID_CHECK:-no} == "yes" ]; then
            echo "IP $IP available."
        else
            echo "IP $IP not available!"
	    exit 1
        fi
    else
        echo "IP format error!"
	exit 1
    fi
}

# 检验ip是否合法
check_ip $1

# [Shell脚本sed命令修改文件的某一行](https://www.cnblogs.com/azureology/p/13039573.html)
# 将 ifcfg_ens33_file 文件的第4改为指定值 
sed -i "4c BOOTPROTO=static" $ifcfg_ens33_file
sed -i "15c ONBOOT=yes" $ifcfg_ens33_file
# 向 ifcfg_ens33_file 追加内容
echo -e "\nIPADDR=$1\nGATEWAY=$ipPrefix.2\nDNS1=$ipPrefix.2" >> $ifcfg_ens33_file

# 重启网卡
# systemctl restart network

# [shell脚本如何提取ip地址最后一段](https://zhidao.baidu.com/question/1689556006930690268.html)
# 覆盖 hostname_file 原本内容
echo "hadoop${ipAddr##*.}" > $hostname_file

#配置 hosts 文件
# [shell获取ip地址前三段](https://juejin.cn/s/shell%E8%8E%B7%E5%8F%96ip%E5%9C%B0%E5%9D%80%E5%89%8D%E4%B8%89%E6%AE%B5)
echo -e "$ipPrefix.$ipSuffix $hostnamePrefix$ipSuffix\n$ipPrefix.$ip1 $hostnamePrefix$ip1\n$ipPrefix.$ip2 $hostnamePrefix$ip2" > $hosts_file

# [linux创建新用户，并自动设置密码为账号+123的shell脚本](https://blog.csdn.net/Zjhao666/article/details/120924794)
# 添加用户 lv 
useradd $userToAdd
# passwd $userToAdd | echo $userToAdd | echo $userToAdd
echo $userToAdd:"$userToAdd" | chpasswd

# sudoers 添加新创建的用户 lv TODO -待完善 找到 /etc/sudoers 中第二个root所在行号并在其下一行添加
sed -i "101c $userToAdd   ALL=(ALL)     NOPASSWD:ALL\n" $sudoers_file

# 关闭防火墙
systemctl stop firewalld
systemctl disable firewalld.service

# 安装必要的软件(安装前判断是否已经安装)
for sft in ${softwares[@]}
do
        if ! which $sft >/dev/null 2>&1; then
                echo "---------安装 $sft --------------"
                yum install -y $sft
        fi
done

# 创建文件夹并更改权限
mkdir /opt/module
mkdir /opt/software
chown $userToAdd:$userToAdd /opt/module 
chown $userToAdd:$userToAdd /opt/software
# 安装完后重启
# Shell编程中的用户输入处理（4）：在shell脚本中，使用read命令获取命令行输入](https://blog.csdn.net/yjk13703623757/article/details/79028738)
read -n 2 -p "Do you want to reboot the machine [Y/N]? " answer
case $answer in
Y | y)
        reboot
;;
N | n)
      echo "ok, good bye"
;;
*)
      echo "error choice"
;;
esac
