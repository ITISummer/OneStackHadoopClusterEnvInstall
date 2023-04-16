#!/bin/bash

#================变量定义区================
sft_path=/opt/software

# []shell遍历目录并提取子目录/文件名字(https://juejin.cn/s/shell%20%E9%81%8D%E5%8E%86%E6%96%87%E4%BB%B6%E5%A4%B9%20%E8%8E%B7%E5%8F%96%E6%96%87%E4%BB%B6%E5%90%8D)
# get all filename in specified path
function getDirFiles(){
    for file in $sft_path/*
    do
	    if test -f $file
	    then
		# 提取不带路径带后缀的文件名
		# echo ${file##*/}
		# 提取后缀
		suffix=${file##*.}
		if [ $suffix='.tar.gz' || $suffix='.tgz' ]
		then
			echo $suffix

		fi
		# 递归遍历
	    #else
		#getdir $file
	    fi
    done
}

getDirFiles $sft_path
