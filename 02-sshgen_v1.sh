#!/bin/bash

#=========================================================
# ===============生成并分发公钥与私钥的脚本===============
# ===============Author: SummerLv=========================
# ===============CreateDate: 2023年3月22日================
#=========================================================

#============================变量定义区=======================
curUser=lv
sshDir=$HOME/.ssh

function judgeUser()
{
	if [ `whoami` == "root" ];then
		echo "非普通用户！请切换到普通用户($curUser)执行此脚本！"
		exit 1
	fi
}

#=====================生成和分发rsa的函数=================
function rsaGenAndDistribution()
{
	# 对于当前运行此脚本的主机来说，如果没有 /home/user/.ssh 目录的话则通过执行 ssh localhost 自动生成 .ssh 目录
	# 注意：对于手动创建的 .ssh 目录来说对于后面进行 ssy-copy-id 命令时会执行成功但是实际上还是需要ssh后输入密码登录 
	echo '========================================================='
	echo '=============当前主机 $USER 用户下完全没有.ssh目录=========='
	echo '========================================================='

	# [https://blog.csdn.net/PlatoWG/article/details/84618566]
	ssh localhost "exit" 
	# ssh $host "cd $HOME/.ssh; sh $HOME/bin/.sshgen.sh" 
	# ssh $host "cd $HOME/.ssh; pwd;" 
	# [关于如何获取当前执行脚本文件名的参考](https://www.v2ex.com/t/302728)
	# [关于如何获取当前执行脚本文件名的参考](https://www.v2ex.com/t/302728)
	cd $sshDir
	echo '========================================================='
	echo "===========开始生成 $1 公钥和私钥并分发==========="
	echo '========================================================='
	# [linux杂谈之ssh静默产生公钥和私钥](https://blog.csdn.net/wzj_110/article/details/107897862)
	ssh-keygen -f ~/.ssh/id_rsa -t rsa -N '' 
	for host2 in $@ 
	do 
		ssh-copy-id $host2 | echo yes
	done
}

#==============ssh到其他主机成功后同步当前脚本=================
function xsync()
{
    # 同步当前脚本到相应目录 TODO 如何自动获取当前脚本名称及路径
    cur_script_file="$HOME/bin/sshgen_v1.sh"
    #2. 遍历集群所有机器
    for host in $@
    do
	echo ============== 向 $host 同步此脚本 ==============
	#3. 判断文件是否存在
	if [ -e $cur_script_file ]
	then
	    #4. 获取父目录
	    pdir=$(cd -P $(dirname $cur_script_file); pwd)
	    #5. 获取当前文件的名称
	    fname=$(basename $cur_script_file)
	    ssh $host "mkdir -p $pdir"
	    rsync -av $pdir/$fname $host:$pdir
	    #6. 添加执行权限
	    # chmod +x $pdir/$fname $host:$pdir
	else
	    echo "$cur_script_file does not exists!"
	fi
    done
}

# 程序入口
function main()
{

	if [ $# -lt 1 ]
	then 
		echo '========================================='
		echo '===============参数个数不够=============='
		echo '========================================='
		exit 1
	fi 

	#[https://www.onitroad.com/jc/linux/centos/check-if-a-directory-exists-in-linux-or-unix-shell.html]
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
			for host2 in $@ 
			do 
				ssh-copy-id $host2
			done
		fi
	else
		# 生成 $HOME/.ssh 目录后生成公钥并群发自身公钥
		rsaGenAndDistribution $@
	fi

}
# 调用main方法
main
# 向其他主机同步此脚本
xsync $@

