#!/bin/bash

#=========================================================
# ===============解压文件到指定目录=======================
# ===============Author: SummerLv=========================
# ===============CreateDate: 2023年4月28日================
#=========================================================

#================变量定义区================
#sftDir=/opt/software
#moduleDir=/opt/module
sftDir=$1
moduleDir=$2

# 解压前判断待解压的文件在目的目录是否存在
function tarFile()
{
	fileName=$1
	baseFileName=$2

    # 判断是否已经存在符合压缩文件名的目录
	echo 目录：$moduleDir$baseFileName
	 if [ -d $moduleDir$baseFileName ]; then
      echo "目录 $moduleDir$baseFileName 已经存在，无需再解压."
    else
      # 解压压缩文件到 moduleDir 目录下
	  echo "================开始解压 $fileName 到 $moduleDir================"
      tar -zxf "${sftDir}/${fileName}" -C "$moduleDir"
    fi
}



# [shell遍历目录并提取子目录/文件名字](https://juejin.cn/s/shell%20%E9%81%8D%E5%8E%86%E6%96%87%E4%BB%B6%E5%A4%B9%20%E8%8E%B7%E5%8F%96%E6%96%87%E4%BB%B6%E5%90%8D)
# get all filename in specified path
function getDirFiles(){
	for file in $sftDir/*
	do
		if test -f $file
		then
			# 提取不带路径带后缀的文件名
			fileName=${file##*/}
			# 判断文件类型 [linux命令file 判断文件类型和文件编码格式](http://www.21yunwei.com/archives/1254)
			# 使用空格作为分隔符，将字符串切分成多个字段
			str=$(echo $(file -i $file) | awk -F " " '{print $2}')

			echo $fileName
			# 去掉最后一个分号
			fileType=$(echo "$str" | sed 's/;*$//')
			if [[ "$fileType"="application/gzip" ]]
			then
				baseFileName=$(basename $fileName .tar.gz)
				baseFileName=$(basename $baseFileName .tgz)
				tarFile $fileName $baseFileName
			elif [[ "$fileType"="application/zip" ]]
			then
				baseFileName=$(basename $fileName .jar)
				tarFile $fileName $baseFileName
			fi
		fi
	done
}

getDirFiles
