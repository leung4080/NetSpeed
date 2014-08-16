#!/usr/bin/env bash 
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

LANG=C
declare -a NIC="";
declare -a NICIP=([0]="null");
declare -i INTERVAL=1;
declare -i COUNT=-1;
declare -i ARGS=4;
declare -a Script_USAGE="Usage: `basename $0` {--help| [-I Interface ] [INTERVAL] [COUNT] }"

#---  FUNCTION  ----------------------------------------------------------------
#          NAME:  getNICs
#   DESCRIPTION:  
#    PARAMETERS:  
#       RETURNS:  NICs array 
#-------------------------------------------------------------------------------
function getNICs(){

case "$OSType" in
  Linux)
    if [ -f /sbin/ifconfig ] ; then
      NIC=$(/sbin/ifconfig -a|awk '$0~/Ethernet/{print $1}')
    else
      echo "/sbin/ifconfig: command not found"
      exit 0;
    fi
    ;;

  SunOS)
    if [ -f /usr/sbin/ifconfig ] ; then
      NIC=$( /usr/sbin/ifconfig -a |awk -F":" '$0~/UP/&&$0!~/(LOOPBACK|POINTOPOINT)/{print $1}')
    else
      echo "/usr/sbin/ifconfig: command not found"
      exit 0;
    fi    
    ;;

  *)
    ;;

esac    # --- end of case ---



}

#---  FUNCTION  ----------------------------------------------------------------
#          NAME:  getNICIP
#   DESCRIPTION:  
#    PARAMETERS:  
#       RETURNS:  
#-------------------------------------------------------------------------------
function getNICIP(){
    if [ -n "$1" ] ; then
      for i in $@ ; do

        case "$OSType"  in
          Linux)
              tip=`/sbin/ifconfig $i | grep inet | cut -d : -f 2 | cut -d " " -f 1`
            ;;

          SunOS)
              tip=` /usr/sbin/ifconfig $i|awk '$0~/inet/{print $2}'`
            ;;
        esac    # --- end of case ---
  	
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
#          NAME:  getNIC_Traffic
#   DESCRIPTION:  
#    PARAMETERS: NIC_NAME RX|TX
#       RETURNS:  
#-------------------------------------------------------------------------------
function getNIC_Traffic(){
    ETH=$1;
    OS_and_DIRECT="$OSType""_""$2"
    case $OS_and_DIRECT in
      Linux_RX)
          VAR=$(cat /proc/net/dev |tr : " "|awk '{if($1=="'$ETH'"){print $2}}')
        ;;
      Linux_TX)
          VAR=$(cat /proc/net/dev |tr : " "|awk '{if($1=="'$ETH'"){print $10}}')
        ;;
      SunOS_RX)
        if [ -f  /usr/bin/kstat  ] ; then   
          VAR=$(/usr/bin/kstat -n $ETH |awk '{if($1=="rbytes"){print $2}}')
        else
          echo "/usr/bin/kstat: command not found"
          exit 0;
        fi
        ;;
      SunOS_TX)
        if [ -f  /usr/bin/kstat  ] ; then   
          VAR=$(/usr/bin/kstat -n $ETH |awk '{if($1=="obytes"){print $2}}')
        else
          echo "/usr/bin/kstat: command not found"
          exit 0;
        fi  
        ;;
    esac    # --- end of case ---
    if [[ $VAR -le 0 ]] ; then VAR=0 ;fi
    echo $VAR;
}

#---  FUNCTION  ----------------------------------------------------------------
#          NAME:  Chk_NIC
#   DESCRIPTION:  
#    PARAMETERS:  
#       RETURNS:  
#-------------------------------------------------------------------------------
function getIFCONFIG_CMD(){

    case "$OSType" in
      Linux)
        IFCONFIG=/sbin/ifconfig
        ;;

      SunOS)
        IFCONFIG=/usr/sbin/ifconfig 
        ;;
    esac    # --- end of case ---

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
      #X="${1}B/s"
      X=$(echo $1 | awk '{printf "%.0f%s\n",$1,"B/s"}')
    elif [[ $1 -gt 1048576 ]];then
      X=$(echo $1 | awk '{printf "%.2f%s\n",$1/1048576,"MB/s"}')
    else
      X=$(echo $1 | awk '{printf "%.2f%s\n",$1/1024,"KB/s"}')
    fi
    echo $X
    return 0;

}


#---  FUNCTION  ----------------------------------------------------------------
#          NAME:  getNICSpeed
#   DESCRIPTION:  
#    PARAMETERS:  
#       RETURNS:  
#-------------------------------------------------------------------------------
function getNICSpeed(){

printf "%8s\t%10s\t%10s\t%10s\t%10s\n\n" TIME NIC RX TX IP;

Index=0 ;
while [ "$Index" -ne $COUNT ] ; 
do

    declare -a RXpre=([0]="null");
    declare -a TXpre=([0]="null");
    declare -a RXnext=([0]="null");
    declare -a TXnext=([0]="null");
 
    for eth in $NIC; do
      RXpre_tmp=$(getNIC_Traffic $eth "RX");
      TXpre_tmp=$(getNIC_Traffic $eth "TX");
      RXpre=( "${RXpre[@]}" "$RXpre_tmp");
      TXpre=( "${TXpre[@]}" "$TXpre_tmp");
    done
    OLDDATE=`date +%k:%M:%S`
    sleep $INTERVAL
    #clear;
    
    for eth in $NIC; do
      RXnext_tmp=$(getNIC_Traffic $eth "RX");
      TXnext_tmp=$(getNIC_Traffic $eth "TX");
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
      RX=$(($RX/$INTERVAL)) 
      TX=$(($TX/$INTERVAL))
      RX=$(format_speed $RX);
      TX=$(format_speed $TX);
      IP=${NICIP[$i]};
      #DATE=$OLDDATE" - "$NOWDATE;
      printf "%8s\t%10s\t%10s\t%10s\t%10s\n" $NOWDATE $eth $RX $TX $IP
      i=$(( $i + 1 ));
    done
    #echo "---------------------------------------------------------------------------------"
    #echo 

    echo ;
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
USAGE_HELP=`echo $* |grep "\-\-help"|wc -l`

if [[ $# -gt $ARGS ]] ||  [[ $USAGE_HELP -ne 0 ]]; then
    echo $Script_USAGE;
    exit;
else
    for i in $*; do
        case "$1" in
        -I)
                INTERFACE="1";
                shift;
                INTERFACE=$1;
                #echo $INTERFACE;
                #continue
                ;;
        *)
            if [[ -z $1 ]] ; then
                continue;
            fi
              
            TEST_NUM=`echo $1| awk '{if($0~/^[0-9]*$/){print "number"}else{print "string"}}'`
            if [[ $TEST_NUM == "string" ]] ; then
                echo " $1 :bad argument "
                exit;
            fi
            if [[ -z $COUNT_SET ]] && [[ -n $INTERVAL_SET ]]; then
                CONUT_SET=1;
                COUNT=$1;
            fi
            if [[ -z $INTERVAL_SET ]] ; then
                INTERVAL_SET=1;
                INTERVAL=$1;
            fi
            
                ;;

        esac
        shift
    done
fi



#if [ $# -gt "$ARGS" ] 
#  then
#  echo $Script_USAGE;
#  exit 0;
#fi
#if [ $# -ne 0 ] ;
#then
#case "$1" in 
#      --help)
#        echo $Script_USAGE;
#        exit 0;
#        ;;
#      *)
#        INTERVAL=$1;
#        if [ $# -gt 1 ] ; then
#          COUNT=$2;
#        fi;
#        ;;
#esac;
#fi

OSType=`uname`
getIFCONFIG_CMD;

if [[ -z $INTERFACE ]] ; then
    getNICs ;
else
    $IFCONFIG $INTERFACE 2>/dev/null 1>&2;
    if [[ $? -ne 0  ]] ; then
      echo "$INTERFACE: no such interface"
      echo $Script_USAGE;
      exit;
    fi
    NIC=$INTERFACE;
fi;
    getNICIP $NIC;
    #echo $NIC;
    #echo $NICIP
    getNICSpeed;



