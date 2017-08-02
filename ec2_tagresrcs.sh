#!/bin/bash
#
# Title: ec2_tagresrcs.sh
#
# Description: ec2_tagresrcs.sh uses AWS CLI to true up the tag values of AWS EC2 resources
# in an AWS region. ec2_tagresrcs.sh uses tag key values of EC2 instances as the data SOA/SOR.
# While the tag key name has to be specific, the value of the key can use wildcards (*). As
# an example, bam*, will grab bam::ssitbamboo.corp.domain.com::bamboo as well as
# Bamboo - Atlassian Migration. costcenter has the list of CostCenter and <finance_cost_center> 
# values paired.
#
# costcenter has the format of CostCenter|<finance_tag_key> using pipes as delimiter
#
# Requirements:
#  - AWS CLI - as current as possible
#  - Python 2.7.12 or 3.5.2
#  - Adequate AWS IAM privileges to update EC2 tags
#    or an instance with an appropriate AWS IAM role
#  - costcenter file in the working directory
#
# USAGE:  ec2_tagresrcs.sh [AWS region] [name | id | ip | tag | bykey]
#
##########################################################################
# variables
# global...
Region=${1}
ToDo=${2}

# function to get the ec2 instance(s) by name and tag info...
function get_ec2instance_name {
   # prompt for the name...
   echo -n "
Instance name: "
   read InstName

   # get the instance id(s) to work from...
   aws ec2 --region ${Region} --output text describe-instances --filters "Name=tag:Name,Values=${InstName}" --query 'Reservations[].Instances[].[InstanceId]' > /var/tmp/${Region}_tagged_ec2inst

   # not knowing if it is one or many, loop through to capture the tag values from the ec2 instance(s)...
   for inst in `cat /var/tmp/${Region}_tagged_ec2inst`
   do
      aws ec2 --region ${Region} --output text describe-instances --instance-ids ${inst} --query 'Reservations[].Instances[].[Tags]' | awk -F"	" '{print $1"|"$2}' | sed "s/| /|/" > /var/tmp/${Region}_tagvalues_${inst}
   done
}

# function to get the ec2 instance(s) by id and tag info...
function get_ec2instance_id {
   # prompt for the id...
   echo -n "
EC2 Instance ID: "
   read InstId

   # get the instance id(s) to work from...
   aws ec2 --region ${Region} --output text describe-instances --filters "Name=instance-id,Values=${InstId}" --query 'Reservations[].Instances[].[InstanceId]' > /var/tmp/${Region}_tagged_ec2inst

   # not knowing if it is one or many, loop through to capture the tag values from the ec2 instance(s)...
   for inst in `cat /var/tmp/${Region}_tagged_ec2inst`
   do
      aws ec2 --region ${Region} --output text describe-instances --instance-ids ${inst} --query 'Reservations[].Instances[].[Tags]' | awk -F"	" '{print $1"|"$2}' | sed "s/| /|/" > /var/tmp/${Region}_tagvalues_${inst}
   done
}

# function to get the ec2 instance(s) by private ip address and tag info...
function get_ec2instance_ip {
   # prompt for the ip address...
   echo -n "
Private IP address: "
   read InstIp

   # get the instance id(s) to work from...
   aws ec2 --region ${Region} --output text describe-instances --filters "Name=private-ip-address,Values=${InstIp}" --query 'Reservations[].Instances[].[InstanceId]' > /var/tmp/${Region}_tagged_ec2inst

   # not knowing if it is one or many, loop through to capture the tag values from the ec2 instance(s)...
   for inst in `cat /var/tmp/${Region}_tagged_ec2inst`
   do
      aws ec2 --region ${Region} --output text describe-instances --instance-ids ${inst} --query 'Reservations[].Instances[].[Tags]' | awk -F"	" '{print $1"|"$2}' | sed "s/| /|/" > /var/tmp/${Region}_tagvalues_${inst}
   done
}

# function to get the ec2 instance(s) by tag key value...
function get_ec2instance_tag {
   # prompt for the tag...
   echo -n "
CostCenter value: "
   read CCVal

   # check validity of value...
   cat costcenter | grep $CCVal > /dev/null 2>&1
   if [ $? = 0 ]
   then
      # get the instance id(s) to work from...
      aws ec2 --region ${Region} --output text describe-instances --filters "Name=tag:CostCenter,Values=${CCVal}" --query 'Reservations[].Instances[].[InstanceId]' > /var/tmp/${Region}_tagged_ec2inst

      # not knowing if it is one or many, loop through to capture the tag values from the ec2 instance(s)...
      for inst in `cat /var/tmp/${Region}_tagged_ec2inst`
      do
         aws ec2 --region ${Region} --output text describe-instances --instance-ids ${inst} --query 'Reservations[].Instances[].[Tags]' | awk -F"	" '{print $1"|"$2}' | sed "s/| /|/" > /var/tmp/${Region}_tagvalues_${inst}
      done
   else
      echo "
ERROR: Invalid CostCenter value. Please reference valid CostCenter values...

`sort costcenter | awk -F"|" '{print $1}'`
"
      exit 1
   fi
}

# function to get the ec2 instance(s) by private ip address and tag info...
function get_ec2instance_bykey {
   # run through the list of CostCenter values and get list of instances...
   for Costc in `cat costcenter | awk -F"|" '{print $1}'`
   do
      # get the instance id(s) to work from...
      aws ec2 --region ${Region} --output text describe-instances --filters "Name=tag:CostCenter,Values=${Costc}" --query 'Reservations[].Instances[].[InstanceId]' >> /var/tmp/${Region}_tagged_ec2inst

      # not knowing if it is one or many, loop through to capture the tag values from the ec2 instance(s)...
      for inst in `cat /var/tmp/${Region}_tagged_ec2inst`
      do
         aws ec2 --region ${Region} --output text describe-instances --instance-ids ${inst} --query 'Reservations[].Instances[].[Tags]' | awk -F"	" '{print $1"|"$2}' | sed "s/| /|/" > /var/tmp/${Region}_tagvalues_${inst}
      done
   done
}

# function to get the list of volumes to tag attached to the instances...
function find_ebsvols_andtag {
   # get the volumes
   for inst in `cat /var/tmp/${Region}_tagged_ec2inst`
   do
      aws ec2 --region ${Region} --output text describe-instances --instance-ids ${inst} --query 'Reservations[].Instances[].[BlockDeviceMappings[].Ebs.VolumeId]' > /var/tmp/${Region}_${inst}_ebsvols
      # run through the instance's volumes and tag them...
      for vol in `cat /var/tmp/${Region}_${inst}_ebsvols`
      do
         for tag in `cat /var/tmp/${Region}_tagvalues_${inst}`
         do
            TKey=`echo ${tag} | awk -F"|" '{print $1}'`
            TVal=`echo ${tag} | awk -F"|" '{print $2}'`
            # tag the volumes with its instance's tag key values...
            aws ec2 --region ${Region} create-tags --resources ${vol} --tags "Key=${TKey},Value=${TVal}"
         done
      done
   done
}

# function to get the list of snapshots from an instance's ebs volume(s)...
function find_ebssnaps_andtag {
   # get the volumes from the instance(s)...
   for inst in `cat /var/tmp/${Region}_tagged_ec2inst`
   do
      # use volume ids to locate snapshots...
      for vol in `cat /var/tmp/${Region}_${inst}_ebsvols`
      do
         for snap in `aws ec2 --region ${Region} --output text describe-snapshots --owner-id self --filters "Name=volume-id,Values=${vol}" --query 'Snapshots[].[SnapshotId]'`
         do
            for tag in `cat /var/tmp/${Region}_tagvalues_${inst}`
            do
               TKey=`echo ${tag} | awk -F"|" '{print $1}'`
               TVal=`echo ${tag} | awk -F"|" '{print $2}'`
               # tag the volumes with its instance's tag key values...
               aws ec2 --region ${Region} create-tags --resources ${snap} --tags "Key=${TKey},Value=${TVal}"
            done
         done
      done
   done
}

# function to clean up /var/tmp...
function clean_up_files {
   ls -1 /var/tmp/${Region}_t* /var/tmp/${Region}_i* > /var/tmp/files_to_remove
   if [ -s /var/tmp/files_to_remove ]
   then
      for file in `cat /var/tmp/files_to_remove`
      do
         rm $file
      done
   fi 
}

# main portion...

# usage and execution
if [ $# -ne 2 ]
then
   echo "
   Two (2) arguments are needed for `basename $0`

   USAGE:  `basename $0` [AWS region] [name | id | ip | tag | bykey]
"
   exit 2
else
   case ${ToDo} in
      "name")
         get_ec2instance_name
         find_ebsvols_andtag
         find_ebssnaps_andtag
         clean_up_files
         ;;
      "id")
         get_ec2instance_id
         find_ebsvols_andtag
         find_ebssnaps_andtag
         clean_up_files
         ;;
      "ip")
         get_ec2instance_ip
         find_ebsvols_andtag
         find_ebssnaps_andtag
         clean_up_files
         ;;
      "tag")
         get_ec2instance_tag
         find_ebsvols_andtag
         find_ebssnaps_andtag
         clean_up_files
         ;;
      "bykey")
         get_ec2instance_bykey
         find_ebsvols_andtag
         find_ebssnaps_andtag
         clean_up_files
         ;;
      *)
         echo "
   Two (2) arguments are needed for `basename $0`

   USAGE:  `basename $0` [AWS region] [name | id | ip | tag | bykey]   
"
         exit 2
         ;;
   esac
fi
exit 0
