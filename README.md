NetSpeed
========
# 网络速率监测脚本 #


Usage: NetSpeed.sh {--help| [-I Interface ] [INTERVAL] [COUNT] }


## 参数说明 ##

    -I Interface  #网卡接口，不指定时，默认为显示所有网卡接口（除了回环接口）。
    INTERVAL #监测时间间隔，单位为秒，默认时间隔为1s。
    COUNT	 #监测次数，默认为无限次。

## 注意 ##

在Solaris系统上执行，需要bash。
暂不支持AIX和HPUX
##