#监控NAS公网IP是否变化，如果和DNS托管商的IP不一致，那就发邮件
#！/usr/bin/env bash

file_path=`pwd -P && cd -P`
duration='1 day ago'


send_time_before=$(date -d "$file_path"/.send  +"+%Y-%m-%d %H:%M:%S" 2>/dev/null)
now_time_check=`date -d "${duration} " "+%Y-%m-%d %H:%M:%S"`
check_ip_change(){
cf_ip=`nslookup nas.takfu.tk 1.1.1.1|grep -v ^$|tail -n1|awk  '{print$2}'`
cur_ip=$(curl http://members.3322.org/dyndns/getip -s)
echo $cf_ip ------- $cur_ip


if [ "$cf_ip" = "$cur_ip" ];then
echo 'yiyang'
else
# 检查是否发过邮件
# 超过一天了，就要发一次
echo now_time:"${now_time_check}" --- send_time_before"${send_time_before}" 
if [ -f "${file_path}/.send" ] && [ "${now_time_check}" -ge "${send_time_before}" ]; then
  send_mail
else
echo "no need send email \n " now_send_time:"${now_time_check}"  pre_send_time"${send_time_before}"
# 一天以内不用发
fi
# 没发过要发
send_mail once"${cur_ip}"

fi

}


send_mail(){

echo now_send_time:"${now_time_check}" >= pre_send_time"${send_time_before}"
echo 'prepare sending mail'
python $file_path/sendmail.py $@
echo  "${now_time_check}" > "${file_path}/.send"
echo update file well

}



main(){
check_ip_change
echo all done
exit $?
}

main
