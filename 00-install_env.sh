#!/bin/bash

#=========================================================
# ===============一键设置前置环境=========================
# ===============Author: SummerLv=========================
# ===============CreateDate: 2023年4月12日================
#=========================================================
# 注意在root用户下执行此脚本或者在非root用户下使用此命令执行此脚本 su - root -s 此脚本所在绝对路径

#=============================变量定义区========================
ifcfg_ens33_file=/etc/sysconfig/network-scripts/ifcfg-ens33
hostname_file=/etc/hostname
hosts_file=/etc/hosts
sudoers_file=/etc/sudoers
my_env_file=/etc/profile.d/my_env.sh
module=/opt/module
software=/opt/software
ipAddr=$1
ipPrefix=${ipAddr%.*}
ipSuffix=${ipAddr##*.}
hostnamePrefix=hadoop
ip1=$[$ipSuffix+1]
ip2=$[$ipSuffix+2]
userToAdd=lv
softwares=(epel-release net-tools vim psmisc  nc  rsync  lrzsz  ntp libzstd openssl-static tree iotop git)
step=0

#=============================日志区========================
# step1="判断用户"
# step2="判断IP"
# step3=`'修改网卡' '$'"$ifcfg_ens33_file"`
# step4=`'修改主机名' '$'"$hostname_file"`
# step5=`'修改hosts' '$'"$hosts_file"`
# step6=`'创建' '$'"$userToAdd" '用户并添加新用户免密' '$'"$sudoers_file" `
# step7="关闭防火墙"
# step8="安装必要软件"
# step9=`'创建' '$'"$module" 和 '$'"$software" '文件夹'`
# step10=`'创建' '$'"$my_env_file" '文件'`


step1="判断用户"
step2="判断IP"
step3="修改网卡 $ifcfg_ens33_file "
step4="修改主机名 $hostname_file"
step5="修改hosts $hosts_file"
step6="创建 $userToAdd 用户并添加新用户免密 $sudoers_file"
step7="关闭防火墙"
step8="安装必要软件"
step9="创建 $module 和 $software"
step10="创建 $my_env_file 文件"

#=========================公共函数引入区======================
source ./commons.sh
#=============================函数区========================
# 实现变量自增
changeStep()
{
	step=$[$step+1]
}

# 打印日志
logger2()
{
	changeStep
	#[shell脚本中echo显示内容带颜色](https://www.cnblogs.com/lr-ting/archive/2013/02/28/2936792.html)
	echo -e "\033[32m ==========$step. $1========== \033[0m" 
}

# [linux的shell脚本判断当前是否为root用户](https://blog.csdn.net/wzy_1988/article/details/8470890)
function judgeUser()
{
	logger2 $step1
	if [ `whoami` != "root" ];then
		logger "ERROR" "非root用户！请切换到root用户执行此脚本！"
		exit 1
	fi

}

# [Shell脚本判断IP是否合法性（多种方法）](https://blog.51cto.com/lizhenliang/1736160)
function check_ip() {
    logger2 $step2
    IP=$ipAddr
    VALID_CHECK=$(echo $IP|awk -F. '$1<=255&&$2<=255&&$3<=255&&$4<=255{print "yes"}')
    if echo $IP|grep -E "^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$">/dev/null; then
        if [ ${VALID_CHECK:-no} == "yes" ]; then
            logger "INFO" "IP $IP 可用."
        else
            logger "INFO" "IP $IP 不可用!"
	    exit 1
        fi
    else
        logger "INFO" "IP 格式错误!"
	exit 1
    fi
}


# [Shell脚本sed命令修改文件的某一行](https://www.cnblogs.com/azureology/p/13039573.html)
function changeIfcfg_ens33()
{
    logger2 $step3
	# 将 ifcfg_ens33_file 文件的第4改为指定值 
	col1=$(sed -n  '/BOOTPROT/=' $ifcfg_ens33_file)
	sed -i "${col1}c BOOTPROTO=static" $ifcfg_ens33_file
	col2=$(sed -n  '/ONBOOT/=' $ifcfg_ens33_file)
	sed -i "${col2}c ONBOOT=yes" $ifcfg_ens33_file
	# 向 ifcfg_ens33_file 追加内容
	#[linux linux sed命令删除一行/多行](https://blog.csdn.net/Trance95/article/details/128793278)
	sed -i '16,25d' $ifcfg_ens33_file
	echo -e "\nIPADDR=$ipAddr\nGATEWAY=$ipPrefix.2\nDNS1=114.114.114.114\nDNS2=8.8.8.8" >> $ifcfg_ens33_file
}

# 重启网卡
# systemctl restart network

# [shell脚本如何提取ip地址最后一段](https://zhidao.baidu.com/question/1689556006930690268.html)
function changeHostname()
{
    logger2 $step4
	# 覆盖 hostname_file 原本内容
	echo "hadoop${ipAddr##*.}" > $hostname_file
}

#配置 hosts 文件
function changeHosts()
{
    logger2 $step5
	# [shell获取ip地址前三段](https://juejin.cn/s/shell%E8%8E%B7%E5%8F%96ip%E5%9C%B0%E5%9D%80%E5%89%8D%E4%B8%89%E6%AE%B5)
	echo -e "$ipPrefix.$ipSuffix $hostnamePrefix$ipSuffix\n$ipPrefix.$ip1 $hostnamePrefix$ip1\n$ipPrefix.$ip2 $hostnamePrefix$ip2" > $hosts_file

}

# [linux创建新用户，并自动设置密码为账号+123的shell脚本](https://blog.csdn.net/Zjhao666/article/details/120924794)
function addUser()
{
    logger2 $step6
	# 添加用户 lv 
	useradd $userToAdd
	# passwd $userToAdd | echo $userToAdd | echo $userToAdd
	echo $userToAdd:"$userToAdd" | chpasswd

	# sudoers 添加新创建的用户 lv TODO -（可利用正则匹配-待完善） 找到 /etc/sudoers 中第二个root所在行号并在其下一行添加
	sed -i "101c $userToAdd   ALL=(ALL)     NOPASSWD:ALL\n" $sudoers_file
}

# 关闭防火墙
function disableFirewall()
{
    logger2 $step7
	systemctl stop firewalld
	systemctl disable firewalld.service
}

# 安装必要的软件(安装前判断是否已经安装)
function insSft()
{
    logger2 $step8
	for sft in ${softwares[@]}
	do
		if ! which $sft >/dev/null 2>&1; then
			# echo -e "\033[33m ==========安装 $sft========== \033[0m" 
			logger "INFO" "安装 $sft"
			yum install -y $sft
		fi
	done
}

# 创建文件夹并更改权限
function addDirAndFile()
{
    logger2 $step9
	mkdir $module
	mkdir $software
	chown $userToAdd:$userToAdd $module
	chown $userToAdd:$userToAdd $software
}

# 创建 /etc/profile.d/my_env.sh 用于后续安装软件后存放环境变量
function createMy_env()
{
    logger2 $step10
	if [ -f "$my_env_file" ];
	then
		  echo "$my_env_file 文件存在"
	else
		  touch $my_env_file
	fi
}

# 安装完后重启
# Shell编程中的用户输入处理（4）：在shell脚本中，使用read命令获取命令行输入](https://blog.csdn.net/yjk13703623757/article/details/79028738)
function isReboot()
{
	read -n 2 -p "是否重启机器 [Y/N]? " answer
	case $answer in
	Y | y)
	        logger "INFO" "开始重启电脑,请重新建立连接..."
		reboot
	;;
	N | n)
	      logger "INFO" "再见，谢谢使用此脚本~"
	;;
	*)
	      logger "INFO" "输入错误！请输入 Y or N"
	      isReboot
	;;
	esac
}

# 主函数
main() 
{
	judgeUser
	check_ip $ipAddr
	changeIfcfg_ens33
	changeHostname
	changeHosts
	addUser
	disableFirewall
	insSft
	addDirAndFile
	createMy_env
	isReboot
}

# 调用主函数
main
