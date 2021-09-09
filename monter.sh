#!/bin/bash
##存储各个服务的状态
declare -A ServiceMap=()
cpuPercent=10
cpuEmailCount=3
resetTime
##进程检测
check_srvProcess() {
	ps -ef | grep "$1" | egrep -v grep
}

##目录检查
check_mkdir() {
	if [ ! -d "/opt/monitor" ]; then
		mkdir /opt/monitor
	fi
}

### monitor_server_register

monitor_server_register() {
	echo "map $1:${ServiceMap[$1]}"
	if check_srvProcess $1 >/dev/null ; then
		#1在线 2离线
		if [ "${ServiceMap[$1]}" != 1 ]; then

			let ServiceMap[$1]=1
			echo "############### service $1 online:${ServiceMap[$1]}"
			DATE_N=$(date "+%Y-%m%d")
			DATE_N_F=$(date "+%F-%T%n")
			echo "service $1 online date:${DATE_N_F}" >>/opt/monitor/svr_$1_"${DATE_N}."log
		fi
	else
		if [ "${ServiceMap[$1]}" != 2 ]; then
			ServiceMap[$1]=2
			echo "############### service $1 offline:${ServiceMap[$1]}"
			DATE_N=$(date "+%Y-%m%d")
			DATE_N_F=$(date "+%Y-%m%d %H:%M:%S")
			echo "service $1 offline date:${DATE_N_F}" >>/opt/monitor/svr_$1_"${DATE_N}."log
		fi

	fi
}
setcpuEmailCount(){
cpuEmailCount=3
}
cpuUse(){

   #计算cpu使用率
   processorNum=$(cat /proc/cpuinfo| grep "processor"| wc -l)
   cpuQuota=`expr $processorNum \* $cpuPercent`
   cpuStatus=`top -b -n1 | fgrep "Cpu(s)" | tail -1 | awk -F'id,' '{split($1, vs, ","); v=vs[length(vs)]; sub(/\s+/, "", v);sub(/\s+/, "", v); printf "%d", 100-v;}'`
   if [[ "$cpuStatus" -gt "$cpuQuota" ]]; then #cpu 使用率大于总额度80% 报警
        echo "CPU使用率%: $cpuStatus"
        echo -e "\033[31m CPU使用率%: $cpuStatus\033[0m"
	if [ $cpuEmailCount -gt 0 ]; then 
        cpuEmailCount=`expr $cpuEmailCount - 1`
	echo "cpuEmailCount:$cpuEmailCount"
	else
		sleep 10
		setcpuEmailCount
        fi
   fi
}
while true; do
	check_mkdir
	while read line; do
		for name in $line; do
		#	echo $name

			#检测微服务状态
			monitor_server_register $name

		done
	done <servicelist.txt
	
	cpuUse &
	#echo "sleep 6 second"
	sleep 6
done

