#!/bin/bash

MYSQL_DB=""
MYSQL_USER=""
MYSQL_PASS=""
PATH_LOCATION=""
POST_LOCATION=""
PATH_LOCATION_MYSQL=""

COLOR_ERROR="31m"
COLOR_SUCCESS="32m"
COLOR_WARNING="33m"


function print_color()
{
    echo -e "\033[${1}${2}\033[0m"
}

function check()
{
    ${2}
    ret=${?}
    if [ ${ret} -eq 0 ];
    then
        print_color ${COLOR_SUCCESS} "[${1}]环境已准备好."
    else
        print_color ${COLOR_ERROR} "[${1}]环境未准备好，请先安装[${1}]."
    fi
    return ${ret}
}

function check_docker()
{
    check docker "docker -v"
}

function check_mysql()
{
    check mysql "mysql -V"
}

function options_mysql_info()
{
    echo -e "数据库名称: (默认lychee)\c"
    read -p "" MYSQL_DB
    if [ -z "${MYSQL_DB}" ];
    then
        MYSQL_DB="lychee"
    fi
    
    echo -e "数据库用户: (默认lychee)\c"
    read -p "" MYSQL_USER
    if [ -z "${MYSQL_USER}" ];
    then
        MYSQL_USER="lychee"
    fi
    
    echo -e "数据库密码: (默认lychee)\c"
    read -p "" MYSQL_PASS
    if [ -z "${MYSQL_PASS}" ];
    then
        MYSQL_PASS="lychee"
    fi
}

function init_mysql()
{
    options_mysql_info
    
    mysql -uroot -e "CREATE DATABASE IF NOT EXISTS ${MYSQL_DB};" && \
    mysql -uroot -e "CREATE USER '${MYSQL_USER}'@'%' IDENTIFIED BY '${MYSQL_PASS}';" && \
    mysql -uroot -e "GRANT ALL PRIVILEGES ON *.* TO '${MYSQL_USER}'@'%' WITH GRANT OPTION;" && \
    mysql -uroot -e "FLUSH PRIVILEGES;"
    
    ret=${?}
    if [ ${ret} -eq 0 ];
    then
        print_color ${COLOR_SUCCESS} "初始化数据库完成."
    else
        print_color ${COLOR_ERROR} "初始化数据库失败."
    fi
    return ${ret}
}

function options_location()
{
    echo -e "本地lychee路径: (默认/data/lychee-data)\c"
    read -p "" PATH_LOCATION
    if [ -z "${PATH_LOCATION}" ];
    then
        PATH_LOCATION="/data/lychee-data"
    fi
}

function options_port()
{
    while :
    do
        echo -e "本地端口: (默认8080)\c"
        read -p "" POST_LOCATION
        if [ -z "${POST_LOCATION}" ];
        then
            POST_LOCATION="8080"
        fi
        
        output=`netstat -anp |grep ${POST_LOCATION}`
        if [ -n "${output}" ];
        then
            print_color ${COLOR_WARNING} "端口${POST_LOCATION}已被占用，请重新选择:"
            continue
        else
            break
        fi
    done
}

function options_mysql_path()
{
    echo -e "本地MySQL路径: (默认/var/lib/mysql/)\c"
    read -p "" PATH_LOCATION_MYSQL
    if [ -z "${PATH_LOCATION_MYSQL}" ];
    then
        PATH_LOCATION_MYSQL="/var/lib/mysql/"
    fi
}

function init_location()
{
    options_location
    
    mkdir -p ${PATH_LOCATION}"/data"
    mkdir -p ${PATH_LOCATION}"/uploads/big"
    mkdir -p ${PATH_LOCATION}"/uploads/thumb"
    chown -R 33:tape ${PATH_LOCATION}"/"
}

function pull_image()
{
    docker pull kdelfour/lychee-docker
}

function start_container()
{
    docker run -it -d -p ${POST_LOCATION}:80 -v ${PATH_LOCATION}"/uploads/":/uploads/ -v ${PATH_LOCATION}"/data/":/data/ -v ${PATH_LOCATION_MYSQL}:/mysql/ kdelfour/lychee-docker
}

function main()
{
    print_color ${COLOR_WARNING} "检查本地Docker环境开始..."
    check_docker
    if [ ${?} -ne 0 ];
    then
        print_color ${COLOR_ERROR} "退出"
        exit 1
    fi
    
    print_color ${COLOR_WARNING} "检查本地MySQL环境开始..."
    check_mysql
    if [ ${?} -ne 0 ];
    then
        print_color ${COLOR_ERROR} "退出"
        exit 1
    fi
    
    
    print_color ${COLOR_WARNING} "初始化数据库开始..."
    init_mysql
    if [ ${?} -ne 0 ];
    then
        print_color ${COLOR_ERROR} "退出"
        exit 1
    fi
    
    print_color ${COLOR_WARNING} "初始化本地目录开始..."
    init_location
    print_color ${COLOR_SUCCESS} "初始化本地目录完成."
    
    print_color ${COLOR_WARNING} "拉取lychee官方镜像开始..."
    pull_image
    print_color ${COLOR_SUCCESS} "拉取lychee官方镜像完成."
    
    options_port
    options_mysql_path
    
    print_color ${COLOR_WARNING} "启动容器开始..."
    start_container
    print_color ${COLOR_SUCCESS} "启动容器完成."
    
    print_color ${COLOR_SUCCESS} "服务启动成功："
    print_color ${COLOR_SUCCESS} "服务端口: ${POST_LOCATION}"
    print_color ${COLOR_SUCCESS} "数据库名称: ${MYSQL_DB}"
    print_color ${COLOR_SUCCESS} "数据库用户: ${MYSQL_USER}"
    print_color ${COLOR_SUCCESS} "数据库密码: ${MYSQL_PASS}"
}

main
