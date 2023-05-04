#!/bin/bash

#=========================================================
# ===============生成并分发公钥与私钥的脚本===============
# ===============Author: SummerLv=========================
# ===============CreateDate: 2023年3月22日================
#=========================================================
#============================使用方式=======================
# 此脚本绝对路径 主机ip1(或 域名1) 主机ip2(或 域名2) 主机ip3(或 域名3)...
# /bin/bash 02-sshgen_v1.sh hadoop102 hadoop103 hadoop104

#=========================全局变量定义区=======================
curUser=lv
sshDir=$HOME/.ssh
curScriptFile="$HOME/bin/02-sshgen_v1.sh"
# [关于如何获取当前执行脚本文件名的参考](https://www.v2ex.com/t/302728)
# echo "========当前脚本名称为：$0========="

#=========================公共函数引入区======================
source ./common_funcs.sh
#========================函数定义区===========================
# 判断执行当前脚本的用户是否为普通用户
function judgeUser()
{
	if [ `whoami` == "root" ];then
		logger "ERROR" "非普通用户！请切换到普通用户($curUser)执行此脚本！"
		exit 1
	fi
}

#生成和分发rsa的函数
function rsaGenAndDistribution()
{
	
	# 对于当前运行此脚本的主机来说，如果没有 /home/user/.ssh 目录的话则通过执行 ssh localhost 自动生成 .ssh 目录
	# 注意：对于手动创建的 .ssh 目录来说对于后面进行 ssy-copy-id 命令时会执行成功但是实际上还是需要ssh后输入密码登录 
	logger "INFO" "当前主机 $curUser 用户下完全没有 .ssh 目录"

	# [通过SSH到远程服务器（不登陆）执行命令](https://blog.csdn.net/PlatoWG/article/details/84618566)
	# 通过以下方式让 Linux 自动创建 .ssh 目录，不要手动创建，手动创建的 .ssh 目录无效
	ssh localhost "exit" | echo yes 
	# ssh $host "cd $HOME/.ssh; pwd;" 
	cd $sshDir
	logger "INFO" "开始生成 $(hostname) 公钥和私钥并分发"
	# [linux杂谈之ssh静默产生公钥和私钥](https://blog.csdn.net/wzj_110/article/details/107897862)
	ssh-keygen -f ~/.ssh/id_rsa -t rsa -N '' 
	for host2 in $@ 
	do 
		ssh-copy-id $host2 | echo yes
	done
}


# 初始化
function init() 
{
	if [ $# -lt 1 ]
	then 
		logger "ERROR" "参数个数不够"
		exit 1
	fi 

	#[Linux/Unix，在Shell脚本中如何判断目录是否存在](https://www.onitroad.com/jc/linux/centos/check-if-a-directory-exists-in-linux-or-unix-shell.html)
	if [ -d "$sshDir" ];then
		cd $sshDir
		# 判断 id_rsa 和 id_rsa.pub 是否存在 
		# [https://blog.csdn.net/ljlfather/article/details/105106875]
		if [[ -e "id_rsa" && -e "id_rsa.pub" ]] 
		then
			for host in $@ 
			do 
				ssh-copy-id $host | echo yes
			done
		else
			ssh-keygen -f ~/.ssh/id_rsa -t rsa -N '' 
			for host in $@ 
			do 
				ssh-copy-id $host | echo yes
			done
		fi
	else
		# 生成 $HOME/.ssh 目录后生成公钥并群发自身公钥
		rsaGenAndDistribution $@
	fi
}

# ssh到其他主机成功后同步当前脚本
function xsync()
{
    #遍历集群所有机器
    for host in $@
    do
		logger "INFO" "向 $host 同步此脚本"
		#判断文件是否存在
		if [ -e $curScriptFile ]
		then
			#获取父目录
			pdir=$(cd -P $(dirname $curScriptFile); pwd)
			#获取当前文件的名称
			fname=$(basename $curScriptFile)
			ssh $host "mkdir -p $pdir"
			rsync -av $pdir/$fname $host:$pdir
			#添加执行权限
			# chmod +x $pdir/$fname $host:$pdir
		else
			logger "ERROR" "$curScriptFile 不存在！"
		fi
    done
}

# 使用 non-login shell 方式在其他机器上执行此脚本
# 前提是：
# 1. 各机器之间能够互相 ping 通
# 2. 当前机器已经成功打通ssh到其他机器
# 3. 各机器设置好了 hostname

function execCurScript()
{
	for host in $@
	do 
		# ssh $host "$curScriptFile $@"
		if [[ $host==$(hostname) ]]
		then
			logger "INFO" "当前主机名为：$host 不会重复执行此脚本"
		else
			ssh $host "$curScriptFile $@"
		fi
	done
}

# 程序入口 注意不要调整main()函数内执行顺序
function main()
{
	init $@
	xsync $@
	# execCurScript $@
}

# 调用main方法
main $@

