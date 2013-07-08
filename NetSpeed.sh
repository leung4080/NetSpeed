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

set -o nounset                              # Treat unset variables as an error


declare -a NIC="";



#---  FUNCTION  ----------------------------------------------------------------
#          NAME:  getNic
#   DESCRIPTION:  
#    PARAMETERS:  
#       RETURNS:  
#-------------------------------------------------------------------------------
function getNic(){

  if [ -f /sbin/ifconfig ] ; then
    NIC=$(/sbin/ifconfig -a|awk '$0~/Ethernet/{print $1}')
  else
    echo "/sbin/ifconfig: command not found"
    exit 0;
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

#===============================================================================
#  MAIN SCRIPT
#===============================================================================

getNic ;

while [ "1" ]
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

    sleep 1
    #clear;
    
    for eth in $NIC; do
      RXnext_tmp=$(cat /proc/net/dev |tr : " "|awk '{if($1=="'$eth'"){print $2}}')
      TXnext_tmp=$(cat /proc/net/dev |tr : " "|awk '{if($1=="'$eth'"){print $10}}')
      RXnext=( "${RXnext[@]}" "$RXnext_tmp")
      TXnext=( "${TXnext[@]}" "$TXnext_tmp")
    done

      echo  -e  "\t `date +%k:%M:%S`"
      printf "\t%s\t%s\n" RX TX;
      i=1
    for eth in $NIC; do
      RX=$((${RXnext[$i]}-${RXpre[$i]}))
      TX=$((${TXnext[$i]}-${TXpre[$i]}))
      RX=$(format_speed $RX);
      TX=$(format_speed $TX);
    
      printf "%s\t%s\t%s\n" $eth $RX $TX
      i=$(( $i + 1 ));
    done
   # eth=$1
   # RXpre=$(cat /proc/net/dev |tr : " "|awk '{if($1=="'$eth'"){print $2}}')
   # TXpre=$(cat /proc/net/dev |tr : " "|awk '{if($1=="'$eth'"){print $10}}')
   # sleep 1
   # RXnext=$(cat /proc/net/dev |tr : " "|awk '{if($1=="'$eth'"){print $2}}')
   # TXnext=$(cat /proc/net/dev |tr : " "|awk '{if($1=="'$eth'"){print $10}}')
   # echo  -e  "\t RX `date +%k:%M:%S` TX"
   # RX=$((${RXnext}-${RXpre}))
   # TX=$((${TXnext}-${TXpre}))
#
 #   RX=$(format_speed $RX);
  #  TX=$(format_speed $TX);
    
   # echo -e "$eth \t $RX   $TX "
    unset RXpre
    unset TXpre
    unset RXnext
    unset TXpre
done
