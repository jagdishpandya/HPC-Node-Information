#! /bin/bash

# Script Name: hpc_node_info.sh
# Author: Jagdish Pandya
# Github Username : jagdishpandya
# Date Created: 2025-03-20
# Last Modified: 2025-03-20
# Purpose: This script gathers and displays information about HPC nodes for  CPU and  memory usage and availability details.
# Usage: ./hpc_node_info.sh
# Dependencies: Slurm
# License: MIT (Optional)


usage() {
  echo "Usage: $(basename "$0")"
  echo "Options:"
  echo "  -h, --help, -help   Display this help message"
  echo "Example: $(echo "sh $0 or ./$0")"
}


while [[ $# -gt 0 ]]; do
  key="$1"
  case $key in
    -h|--help|-help)
      usage
      exit 0
      ;;
     *)
   echo "Unknown option: $1"
     usage
     exit 1
     ;;
  esac
done

# Function to check exit status
cleanup_and_exit() {
  if [ -f ${FILE_NAME} ]; then
  	rm  ${FILE_NAME}
  fi
  exit 0
}

trap cleanup_and_exit SIGINT SIGTERM


# Making Temporary Files
BASE_DIR=${HOME}"/tmp_dir"
[ -d ${BASE_DIR} ] || mkdir ${BASE_DIR}
FILE_NAME=${BASE_DIR}"/temp_mem.txt"

touch ${FILE_NAME}

# Counting total nodes in cluster
total_nodes=$(sinfo -N | grep -v NODELIST | awk '{print $1}' | sort | uniq | wc -l)

##################
# Change institute name as required in below first two lines

CLUSTER_NAME="Your_Cluster_Name"
INST_NAME="XYZ, ABCD"

# If you want to take hpc cluster name as per defined in slurm, uncommnet below line:
#CLUSTER_NAME=$(cat /etc/slurm/slurm.conf | grep ^ClusterName | awk -F= '{print $2}')

WELCOME="WELCOME TO ${CLUSTER_NAME} at ${INST_NAME}"

##################

# Counting nodes all used memeory
TMPFS=$IFS
IFS=$'\n'
for line in $(squeue -o "%.18i %.9P %.8j %.8u %.8T %.10M %.9l %.6D %R %m" | grep RUNNING | awk '{print  $(NF-1),$NF}'  | sed 's/\[//'| sed 's/\]//' ); do
        node_nos=$(echo ${line} | awk '{print $1}')
        prefix=$(echo ${node_nos} | awk -F[0-9] '{print $1}')
        mem=$(echo ${line} | awk '{print $2}')
        if [[ ${mem} == *M ]]; then
		mem=$(( ${mem%M} / 1024 ))"G"
        fi

        IFS=$TMPFS
        for node in $(echo ${node_nos} | perl -pe 's/(\d+)-(\d+)/join(",",$1..$2)/eg' | sed "s/,/ $prefix/g"); do
		echo ${node}" "$(echo ${mem} | sed 's/G//')" "${prefix} >> ${FILE_NAME}
        done
        TMPFS=$IFS
        IFS=$'\n'
done

IFS=$TMPFS

##############################################################

echo ""
echo -e '\033[0;34m ----------------------------------------------------------------------------------------';
echo "  ----------------- ${WELCOME} ---------------------"
echo -e '\033[0;34m ----------------------------------------------------------------------------------------';
#-----------------------------------------------------------------------------------

echo -en '\033[0;34m\t\t   Status of the '"${total_nodes}"' nodes '"${CLUSTER_NAME}"' HPC cluster ';
DATE=`date +"- %d %B %Y"`
Time=`date +"- %H:%M"`
echo -e "\n\t\t      Date:$DATE, Time:$Time hrs\n"
echo " ----------------------------------------------------------------------------------------"
echo -e "\e[1;31m JOBS SUBMITTED            JOBS RUNNING          JOBS IN Q     JOBS IN HOLD\e[m"
echo -e "\t  $S\t\t $R\t\t\t$Q\t\t $H"

jobs_sub=$(squeue | tail -n +2 | awk '{print $5}' | wc -l)
jobs_run=$(squeue | tail -n +2 | awk '{print $5}' | grep R | wc -l)
jobs_q=$(squeue | tail -n +2 | awk '{print $5}' | grep PD | wc -l)
jobs_hold=$(squeue | tail -n +2 | awk '{print $5}' | grep RD | wc -l)

echo -e "\t$jobs_sub\t\t\t$jobs_run\t\t\t$jobs_q\t\t$jobs_hold"
echo
echo " -----------------------------------------------------------------------------------------"
echo -e "\e[1;31m NODES         STATE                       Memory                            Processors\e[m"
echo "                               ------------------------------           ------------------"
echo -e "\e[1;31m                               ALLOC*     USED    AVAIL  TOTAL            USED  AVAIL TOTAL\e[m"
echo "------------------------------------------------------------------------------------------"

# Gathering all partition names
part_name=$(for part in $(sinfo -a | tail -n +2 | awk '{print $1}' | sort | uniq | sed 's/*//'); do echo -n $part","; done | sed 's/,$//')

TEMPFS=$IFS
IFS=$'\n'; for line in $(sinfo -o "%8n  %14C %8e %6T %6X %5Y %m" -p ${part_name} | tail -n +2 | sort -V)
do
	node=$(echo $line | awk '{print $1}')
	state=$(echo $line | awk '{print $4}' | sed 's/alloca/closed/' | sed 's/idle/avail/')
	
	mem=$(echo $line | awk '{print $7}')
	total_mem=$(echo $mem | awk '{print "scale=2; "$1" *  1024 * 1024"}' | bc | awk '{ suffix=" KMG"; for (i=1; $1>1024 && i < length(suffix); i++) $1/=1024; print int($1) substr(suffix, i, 1); }')
	free_mem=$(echo $line | awk '{print "scale=2; "$3" * 1024 * 1024"}' | bc | awk '{ suffix=" KMG"; for (i=1; $1>1024 && i < length(suffix); i++) $1/=1024; print int($1) substr(suffix, i, 1), $3; }')
	mem2=$(echo "scale=2; $mem * 1024" | bc)
	free_mem_num=$(echo $line | awk '{print $3}')
	
	used_mem=$(echo "$mem $free_mem_num" | awk '{print "scale=2; ( "$1 " - "$2" ) *  1024 * 1024"}' | bc | awk '{ suffix=" KMG"; for (i=1; $1>1024 && i < length(suffix); i++) $1/=1024; print int($1) substr(suffix, i, 1); }')
	
	alloc_mem=0
	for node_mem in $(cat ${FILE_NAME} | sed 's/G//' | grep -w ${node} | awk '{print $2}'); do
                alloc_mem=$(echo "${node_mem} + ${alloc_mem}" | bc)
        done
	
	free_mem=$(echo "$(echo ${total_mem} | sed 's/G//')  - ${alloc_mem} - 16" | bc)

	if (( ${alloc_mem} < $(echo ${used_mem} | sed 's/G//' | sed 's/M//') )); then
		if [[ ${used_mem} == *"M" ]]; then
			alloc_mem=$(echo $(echo ${used_mem} | sed 's/M//')" / 1024" | bc | sed 's/M//')
		else 
			alloc_mem=$(echo ${used_mem} | sed 's/G//' | sed 's/M//')
		fi
	fi

	total_cpu=$(echo $line | awk '{print $2}' | sed 's/\// /g' | awk '{print $4}') 
	avail_cpu=$(echo $line | awk '{print $2}' | sed 's/\// /g' | awk '{print $2}')
	used_cpu=$(echo $line | awk '{print $2}' | sed 's/\// /g' | awk '{print $1}')

	echo -e "$node\t\t$state\t\t$alloc_mem"G"\t$used_mem\t$free_mem"G"\t$total_mem\t\t$used_cpu\t$avail_cpu\t$total_cpu"
done
echo "---------------------------------------------------------------------------------------------------"
echo "* ALLOC Memory is defined memory be user + used memory by system"
IFS=$TEMPFS

rm  ${FILE_NAME}
