#!/bin/bash

#----------------------------------------------------------
# 把该文件放置到 /etc/profile.d/ 目录下，并使用chmod +x show_sysinfo_when_suc_login.sh 使其可被执行
#----------------------------------------------------------

# 颜色
GREEN="\033[1;32m"
YELLOW="\033[1;33m"
CYAN="\033[1;36m"
RESET="\033[0m"

# 获取基本信息
HOSTNAME=$(hostname)
UPTIME=$(uptime -p | sed 's/up //')
LOADAVG=$(uptime | awk -F 'load average:' '{print $2}' | sed 's/^ //')

# 内存
read MEM_TOTAL MEM_USED <<<$(free -m | awk '/Mem:/ {print $2, $3}')
MEM_PCT=$((MEM_USED * 100 / MEM_TOTAL))

# IP
IP_ADDR=$(hostname -I | awk '{print $1}')

# CPU 使用率（top方式）
CPU_IDLE=$(top -bn2 | grep "Cpu(s)" | tail -n1 | awk -F ',' '{print $4}' | grep -o '[0-9.]*')
CPU_USAGE=$(awk "BEGIN {printf \"%.0f\", 100 - $CPU_IDLE}")

# 输出系统信息
echo -e "\n${GREEN}恭喜成功登录系统，当前系统信息如下！${RESET}"
echo -e "${YELLOW}---------------------------------------------${RESET}"
#echo -e "${CYAN}系统信息如下：${RESET}"
#echo -e "${YELLOW}---------------------------------------------${RESET}"

printf "| %-8s | %-30s |\n" "资源    "         "   使用情况"
printf "|----------|--------------------------------|\n"
printf "| %-8s | %-30s |\n" "IP地址  " "$IP_ADDR"
printf "| %-8s | %-30s |\n" "CPU"    "$CPU_USAGE%"
printf "| %-8s | %-30s |\n" "内存    "    "${MEM_USED}MB / ${MEM_TOTAL}MB (${MEM_PCT}%%)"
printf "| %-8s | %-30s |\n" "负载情况" "$LOADAVG"
printf "| %-8s | %-30s |\n" "运行时长"   "$UPTIME"

echo -e "${YELLOW}---------------------------------------------${RESET}"
echo -e "${CYAN}磁盘挂载信息${RESET}"
echo -e "${YELLOW}-------------------------------------------------${RESET}"

# 打印磁盘使用情况（排除 tmpfs 和 devtmpfs）
printf "| %-10s | %-10s | %-10s | %-6s |\n" "Mount" "Used" "Total" "Usage"
printf "|------------|------------|------------|--------|\n"
df -h -x tmpfs -x devtmpfs | awk 'NR>1 {
    printf "| %-10s | %-10s | %-10s | %-6s |\n", $6, $3, $2, $5
}'

echo -e "${YELLOW}-------------------------------------------------${RESET}"
echo -e "${GREEN}Thanks For 'https://mp.weixin.qq.com/s/Yqf0UrfOH-JAEYGUpu5uow'！${RESET}\n"
echo -e "${GREEN}开始你的表演，操作需谨慎！${RESET}\n"