#!/usr/bin/env bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH
# --------------------------------------------------------------
#	项目: CloudflareSpeedTest 自动更新 dnsmasq 配置文件
#	版本: 1.0.1
#	作者: XIU2,Sving1024
#	项目: https://github.com/XIU2/CloudflareSpeedTest
# --------------------------------------------------------------

_UPDATE() {
	echo -e "开始测速..."
	BESTIP=""
	BESTIP_IPV6="::"
	# 这里可以自己添加、修改 CFST 的运行参数
	./cfst -o "result_hosts.txt"
	# 需要测速 IPv6 请取消注释
	#./cfst -o "result_hosts_ipv6.txt" -f ipv6.txt

	# 如果需要 "找不到满足条件的 IP 就一直循环测速下去"，那么可以将下面的两个 exit 0 改为 _UPDATE 即可
	[[ ! -e "result_hosts.txt" ]] && echo "CFST 测速结果 IP 数量为 0，跳过下面步骤..." && exit 0

	# 下面这行代码是 "找不到满足条件的 IP 就一直循环测速下去" 才需要的代码
	# 考虑到当指定了下载速度下限，但一个满足全部条件的 IP 都没找到时，CFST 就会输出所有 IP 结果
	# 因此当你指定 -sl 参数时，需要移除下面这段代码开头的 # 井号注释符，来做文件行数判断（比如下载测速数量：10 个，那么下面的值就设在为 11）
	#[[ $(cat result_hosts.txt|wc -l) > 11 ]] && echo "CFST 测速结果没有找到一个完全满足条件的 IP，重新测速..." && _UPDATE

	BESTIP=$(sed -n "2,1p" result_hosts.txt | awk -F, '{print $1}')
	# 需要测速 IPv6 请取消注释
	#BESTIP_IPV6=$(sed -n "2,1p" result_hosts_ipv6.txt | awk -F, '{print $1}')

	if [[ -z "${BESTIP}" ]]; then
		echo "CFST 测速结果 IP 数量为 0，跳过下面步骤..."
		exit 0
	fi
	echo ${BESTIP} > nowip_hosts.txt
	echo -e "最优 IPv4 IP 为 ${BESTIP}\n"
	# 需要测速 IPv6 请取消注释
	#echo -e "最优 IPv6 IP 为 ${BESTIP_IPV6}\n"

    [[ -f cloudflare.conf ]] && rm cloudflare.conf

    cat site.conf | while read domain
    do
        if [[ ${domain:0:1} != "#" && ${domain} != "" ]]; then 
			echo "address=/${domain}/${BESTIP}" >> "cloudflare.conf"
			echo "address=/${domain}/${BESTIP_IPV6}" >> "cloudflare.conf"
		fi
    done

    [[ -f /etc/dnsmasq.d/cloudflare.conf ]] && rm /etc/dnsmasq.d/cloudflare.conf
    cp cloudflare.conf /etc/dnsmasq.d/cloudflare.conf
    systemctl restart dnsmasq.service
}

_UPDATE