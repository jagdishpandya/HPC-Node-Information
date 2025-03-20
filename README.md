# HPC-Node-Information
This script is only for HPC Slurm users.
This Script requires slurm.

A Linux Bash script to generate  a comprehensive overview of resource utilization on an HPC cluster nodes.
Script Description: HPC Cluster Resource Monitor

This will help HPC Slurm users 

This script is only for Slurm users

This script, hpc_node_info.sh, provides a comprehensive overview of resource utilization on an HPC cluster nodes. It gathers and displays information about memory and CPU usage, including:

* Total system memory
* Memory allocated to the current users
* System-wide used memory
* Available free memory
* Total CPU cores
* Currently used CPU cores
* Available free CPU cores

Usage:

./hpc_node_info.sh
or
sh hpc_node_info.sh


Options:

* -h, --help, -help: Display this help message.

###########################################################################
# Change institute name as required in below two lines in script
CLUSTER_NAME="Your_Cluster_Name"
INST_NAME="XYZ, ABCD"
############################################################################
# If you want to take hpc cluster name as per defined in slurm, uncommnet below line:
#CLUSTER_NAME=$(cat /etc/slurm/slurm.conf | grep ^ClusterName | awk -F= '{print $2}')
############################################################################

Example:

* ./hpc_node_info.sh
* ./hpc_node_info.sh -h

Please mail me for any queries / bugs / modifications

Author Information:

Jagdish Pandya
GitHub - jagdishpandya
jagdishpandya@yahoo.com
jagdishpandya@gmail.com
jagdish.pandya@appcominfotech.com

This script is intended to provide quick and easy access to resource usage statistics on HPC cluster nodes, aiding in job management and performance monitoring.
