#!/bin/bash
sh_ver="1.0.0"
ver_desc="该版本只支持实战平台的发布"
Green_font_prefix="\033[32m" && Red_font_prefix="\033[31m" && Green_background_prefix="\033[42;37m" && Red_background_prefix="\033[41;37m" && Font_color_suffix="\033[0m"
Info="${Green_font_prefix}[信息]${Font_color_suffix}"
Error="${Red_font_prefix}[错误]${Font_color_suffix}"
Tip="${Green_font_prefix}[注意]${Font_color_suffix}"




oneclick_video(){
    video_dir=/root/video/video-security/video-security
    echo -e "${Info}:准备拉取最新代码"
    cd $video_dir && git pull
    if [ $? -ne 0 ]; then
           log_id=git log|grep commit|head -n1
           echo -e "${Tip}:本地代码已被修改，强制回滚. log_id:" $log_id
           git reset --hard $log_id && git pull
           if [ $? -ne 0 ]; then
           echo -e "${Error}: 拉取代码错误,stop the world"
           exit 1
           fi
    fi
    echo -e "${Info}:更新代码成功!准备打包"
    mvn clean deploy -DskipTests=true && cd video-security-web/target && jps -l |grep video|awk '{print $1}'|xargs -i kill -9 {}
    if [ $? -ne 0 ]; then
	echo -e "${Error}: error in package. stop everything!"
        exit -1
    fi
    echo -e "${Info}:boot video-security..."
    sleep 1s
    chmod u+x *.jar
    nohup java -jar video-security*.jar 2>&1 &
    sleep 2s
    clear
    echo -e "${Info}:Boot done "
    read -r -p '查看启动日志[y/N]' cs
    case $cs in
         [yY][eE][sS]|[yY])
           echo -e "${Info}: yes"
           sleep 1s
	       tailf nohup.*
           ;;
         *)
           echo -e "${Info}: no. pass script"
           exit 1
           ;;
    esac
}

oneclick_combat(){

    combat_dir=/root/cbt
    ldir=/data/logs/combat-platform/combat-platform.log
    prop=/root/cbt/conf/log4j.properties

    cd $combat_dir


    read_func

    echo -e "${Info}: Spark-submit Mode: ${depMode}"

    echo -e "${Info}: kill server..."

    kill_combat

    echo -e "${Info}:boot combat-platform..."
    en=4
    ec=32
    chmod u+x $combat_dir/combat-platform.jar
    sleep 1s
	nohup $SPARK_HOME/bin/spark-submit \
        --master yarn \
        --deploy-mode client \
	--name onlineAnalyse \
	--num-executors ${en} \
	--driver-memory 3g \
	--driver-cores 2 \
	--executor-memory 35g \
	--executor-cores ${ec} \
	--driver-java-options "-Dlog4j.configuration=file:${prop} \
	-Dexecutor.num=${en} -Dexecutor.core=${ec} \
	-XX:+PrintGCApplicationConcurrentTime -Xloggc:gc.log" \
	--conf spark.driver.port=20002 \
        --conf spark.default.parallelism=300 \
        --conf spark.driver.maxResultSize=2g \
        --conf spark.kryoserializer.buffer.max=256m \
        --conf spark.kryoserializer.buffer=128m \
        --conf spark.memory.fraction=0.8 \
	$combat_dir/combat-platform.jar 2>&1 &
    sleep 2s
    clear
    echo -e "${Info}:Boot done "
    read -r -p '查看启动日志[y/N]' cs
    case $cs in
         [yY][eE][sS]|[yY])
           echo -e "${Info}: yes"
           sleep 1s
	       tailf ${ldir}
           ;;
         *)
           echo -e "${Info}: no. pass script"
           exit 1
           ;;
    esac



}



read_func(){
    depMode=""
    while    read -p 'select spark submit master No. [1:local] [2:yarn-client] [3:yarn-cluster]: ' dep
    do
    case $dep in
        1)
            echo -e 'Using localMode.\ninput thread numba'
            read -p 'default is [2]: ' numba
            if [ -z $numba ];then
                numba=0
            fi

            numba= `echo "$numba*1" | bc `
            echo -e "${Info}:Thread numba: ${numba}"
            if [ $numba -gt 0 ]
            then
                echo -e "${Info}:Using ${numba} thread boot spark!"
                depMode="local[${numba}]"
            else
                echo -e "${Info}:Using default."
                depMode="local[2]"
            fi
            ;;
        2)
            depMode='yarn-client'
            echo -e "${Info}: Using yarn-client Mode."
            ;;
        3)
            depMode='yarn-cluster'
            echo -e "${Info}: Using yarn-cluster Mode."
            ;;
        *)

            ;;
    esac
    if [ ! -z $depMode ]
    then
        break
    else
        echo -e "${Error}提交模式不可识别,请输入正确数字"

        sleep 1s
    fi
    done
}

kill_video(){
  jps -l |grep video|awk '{print $1}'|xargs -i kill -15 {}
  if [ $? -eq 0 ]
  then
     echo -e "${Info}: 一杀死视频安防"
  else
     echo -e "${Warn}: 杀死失败"
  fi
}

kill_combat(){
  jps -l |grep SparkSubmit|awk '{print $1}'|xargs -i kill -15 {}
  if [ $? -eq 0 ]
  then
     echo -e "${Info}: 一杀死实战平台"
  else
     echo -e "${Warn}: 杀死失败"
  fi
}



check_video(){
n=$(jps -l |grep video|wc -l)
if [ $n -gt 0 ]
   then
   	echo -e "${Info}:已开启"
   else
	echo -e "${Error}:未开启"
fi
}


check_combat(){
n=$(jps -l |grep SparkSubmit|wc -l)
if [ $n -gt 0 ]
   then
        echo -e "${Info}:已开启"
   else
        echo -e "${Error}:未开启"
fi
}


expand_menu(){
clear
echo && echo -e " 一键安装部署管理 ${Red_font_prefix}[v${sh_ver}]${Font_color_suffix}
--  奇葩脚本 | br7roy.github.io --
--  ${ver_desc} --
———————————资源管理————————————
 ${Green_font_prefix}1.${Font_color_suffix}  安装 视频安防
 ${Green_font_prefix}2.${Font_color_suffix}  安装 实战平台
———————————状态管理————————————
 ${Green_font_prefix}3.${Font_color_suffix}  检测 视频安防
 ${Green_font_prefix}4.${Font_color_suffix}  检测 实战平台
 ${Green_font_prefix}5.${Font_color_suffix}  杀死 视频安防
 ${Green_font_prefix}6.${Font_color_suffix}  杀死 实战平台
————————————杂项管理————————————
 ${Green_font_prefix}7.${Font_color_suffix}  启动 视频安防(使用最新版本代码)
 ${Green_font_prefix}8.${Font_color_suffix}  启动 实战平台(使用最新版本代码)
 ${Green_font_prefix}9.${Font_color_suffix}  启动 大数据集群
 ${Green_font_prefix}10.${Font_color_suffix} 关闭 大数据集群
 ${Green_font_prefix}11.${Font_color_suffix} 优化 大数据集群
 ${Green_font_prefix}12.${Font_color_suffix} 退出脚本
————————————————————————————————" && echo


echo
read -p " 请输入数字[1-12]: " num
case "$num" in
        1)
        install_video
        ;;
        2)
        install_combat
        ;;
        3)
        check_video
        ;;
        4)
        check_combat
        ;;
        5)
        kill_video
        ;;
        6)
        kill_combat
        ;;
        7)
        oneclick_video
        ;;
        8)
        oneclick_combat
        ;;
        9)
        boot_bigdata
        ;;
        10)
        shutdown_bigdata
        ;;
        11)
        optimize_bigdata
        ;;
        12)
        exit 1
        ;;
        *)
        clear
        echo -e "${Error}:请输入正确数字 [1-12]"
        sleep 2s
        expand_menu
        ;;

esac

}


expand_menu
