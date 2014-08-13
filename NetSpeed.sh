#!/bin/bash - 
#===============================================================================
#
#          FILE: NetSpeed.sh
# 
#         USAGE: ./NetSpeed.sh 
# 
#   DESCRIPTION: 
# 
#       OPTIONS: ---
#  REQUIREMENTS: ---
#          BUGS: ---
#         NOTES: ---
#        AUTHOR: LiangHuiQiang (), 
#  ORGANIZATION: 
#       CREATED: 2013/7/8 15:59:02 中国标准时间
#      REVISION:  ---
#===============================================================================

#set -o nounset                              # Treat unset variables as an error


declare -a NIC="";
declare -a NICIP=([0]="null");
declare -i INTERVAL=1;
declare -i COUNT=-1;
declare -i ARGS=2;
#---  FUNCTION  ----------------------------------------------------------------
#          NAME:  getNic
#   DESCRIPTION:  
#    PARAMETERS:  
#       RETURNS:  
#-------------------------------------------------------------------------------
function getNic(){

  if [ -f /sbin/ifconfig ] ; then
    if [ "$OS" = "SunOS" ] ; then
      NIC=$(ifconfig -a|awk '$0!~/LOOPBACK/&&$2~/flags/{print $1}'|sed 's/.$//')
    else
    NIC=$(/sbin/ifconfig -a|awk '$0~/Ethernet/{print $1}')
    fi

  else
    echo "/sbin/ifconfig: command not found"
    exit 0;
  fi

}

#---  FUNCTION  ----------------------------------------------------------------
#          NAME:  getNicIP
#   DESCRIPTION:  
#    PARAMETERS:  
#       RETURNS:  
#-------------------------------------------------------------------------------
function getNicIP(){
    if [ -n "$1" ] ; then
      for i in $@ ; do
	tip=`/sbin/ifconfig $i | grep inet | cut -d : -f 2 | cut -d " " -f 1`
	if [ -z "$tip" ] ;then

		tip="noIP"
	fi

        NICIP=(  "${NICIP[@]}" "$tip" )
      done
    else
      echo "none"
      exit 0
    fi

}



#---  FUNCTION  ----------------------------------------------------------------
#          NAME:  format_speed
#   DESCRIPTION:  
#    PARAMETERS:  
#       RETURNS:  
#-------------------------------------------------------------------------------

function format_speed(){
      X=""; 
  if [[ $1 -lt 1024 ]];then
      X="${1}B/s"
    elif [[ $1 -gt 1048576 ]];then
      X=$(echo $1 | awk '{print $1/1048576 "MB/s"}')
    else
      X=$(echo $1 | awk '{print $1/1024 "KB/s"}')
    fi
    echo $X
    return 0;

}


#---  FUNCTION  ----------------------------------------------------------------
#          NAME:  getNicSpeed
#   DESCRIPTION:  
#    PARAMETERS:  
#       RETURNS:  
#-------------------------------------------------------------------------------
function getNicSpeed(){

printf "%10s\t%10s\t%10s\t%10s\t%10s\n" TIME NIC RX TX IP;
Index=0 ;
while [ "$Index" -ne $COUNT ] ; 
do

    declare -a RXpre=([0]="null");
    declare -a TXpre=([0]="null");
    declare -a RXnext=([0]="null");
    declare -a TXnext=([0]="null");
 
    for eth in $NIC; do
      RXpre_tmp=$(cat /proc/net/dev |tr : " "|awk '{if($1=="'$eth'"){print $2}}')
      TXpre_tmp=$(cat /proc/net/dev |tr : " "|awk '{if($1=="'$eth'"){print $10}}')
      RXpre=( "${RXpre[@]}" "$RXpre_tmp");
      TXpre=( "${TXpre[@]}" "$TXpre_tmp");
    done

    sleep $INTERVAL
    #clear;
    
    for eth in $NIC; do
      RXnext_tmp=$(cat /proc/net/dev |tr : " "|awk '{if($1=="'$eth'"){print $2}}')
      TXnext_tmp=$(cat /proc/net/dev |tr : " "|awk '{if($1=="'$eth'"){print $10}}')
      RXnext=( "${RXnext[@]}" "$RXnext_tmp")
      TXnext=( "${TXnext[@]}" "$TXnext_tmp")
    done

      NOWDATE=`date +%k:%M:%S`
      #printf "%10s\t%10s\t%10s\t%10s\n" NIC RX TX IP;
      # echo "---------------------------------------------------------------------------------"   
      i=1
    for eth in $NIC; do
      RX=$((${RXnext[$i]}-${RXpre[$i]}))
      TX=$((${TXnext[$i]}-${TXpre[$i]}))
      RX=$(format_speed $RX);
      TX=$(format_speed $TX);
      IP=${NICIP[$i]};
    
      printf "%10s\t%10s\t%10s\t%10s\t%10s\n" $NOWDATE $eth $RX $TX $IP
      i=$(( $i + 1 ));
    done
    #echo "---------------------------------------------------------------------------------"
    #echo 

    unset RXpre
    unset TXpre
    unset RXnext
    unset TXpre
    Index=$(($Index+1))
done

}

#===============================================================================
#  MAIN SCRIPT
#===============================================================================

if [ $# -gt "$ARGS" ] 
  then
  echo "Usage: `basename $0` {--help| [INTERVAL] [COUNT] }"
  exit 0;
fi
if [ $# -ne 0 ] ;
then
case "$1" in 
      --help)
        echo "Usage: $0 {--help| [INTERVAL] [COUNT] }"
        exit 0;
        ;;
      *)
        INTERVAL=$1;
        if [ $# -gt 1 ] ; then
          COUNT=$2;
        fi;
        ;;
esac;
fi

OS=`uname`
getNic ;
getNicIP $NIC;
#echo $NIC;
#echo $NICIP
getNicSpeed;

