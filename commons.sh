#!/bin/bash


# 打印日志
logger()
{
	logLevel=$1
	logStr=$2
	case $logLevel in
	"INFO")
		#[shell脚本中echo显示内容带颜色](https://www.cnblogs.com/lr-ting/archive/2013/02/28/2936792.html)
		# 绿色字
		echo -e "\033[32m ==========$logStr========== \033[0m" 
	;;
	"ERROR")
		# 红色字
		echo -e "\033[31m ==========$logStr========== \033[0m" 
	;;
	*)
		# 蓝色字
		echo -e "\033[34m ==========未指定类型========== \033[0m" 
	;;
	esac
}
