#!/bin/bash
sh_ver="0.0.1"
Green_font_prefix="\033[32m" && Red_font_prefix="\033[31m" && Green_background_prefix="\033[42;37m" && Red_background_prefix="\033[41;37m" && Font_color_suffix="\033[0m"
Info="${Green_font_prefix}[信息]${Font_color_suffix}"
Error="${Red_font_prefix}[错误]${Font_color_suffix}"
Tip="${Green_font_prefix}[注意]${Font_color_suffix}"

video_dir=/root/video/video-security/video-security


oneclick_video(){
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

check_video(){
n=$(jps -l |grep video|wc -l)
if [ $n -gt 0 ]
   then
   	echo -e "${Info}:已开启"
   else
	echo -e "${Error}:未开启"
fi
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
expand_menu(){
clear
echo && echo -e " 一键安装部署管理 ${Red_font_prefix}[v${sh_ver}]${Font_color_suffix}
--  奇葩脚本 | br7roy.github.io --
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
