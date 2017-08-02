#!/bin/bash
#
# Title: ebs_snap_tagger.sh
#
# Description: snap_tagger.sh is used to tag EC2-related infrastructure
# It looks for snapshots without the tag key, <tag_key>, and uses the
# tags from the EBS volume the snap was created. If the EBS volume no
# longer exists the tag values assigned are <tag_key>:sysops,
# Env:dev, <tag_key>:1234.
#
# Usage: ebs_snap_tagger.sh [AWS_Region]
#
# Requirements:
#   - Root level access to a UNIX/Linux system. Sudo will do. Or an EC2 instance
#     with an IAM role that grants EC2, full access
#   - AWS CLI (pip install awscli)
#   - AWS CLI is root's/superuser's path
#   - Proper AWS IAM role or user with EC2 full access (minimally)
#   - Python 2.7.10 or 3.5.2 with Boto or Boto3 installed
##################################################################### 
# variables...
export PATH=${PATH}:/usr/local/bin
Region=${1}

# function to work through the snapshot tagging process...
function tag_snaps {
   # what snapshots are missing the <tag_key> tag key...
   aws ec2 --region ${Region} --output text describe-snapshots --owner-id self --query 'Snapshots[?!not_null(Tags[?Key == `<tag_key>`].Value)] | [].[SnapshotId]' > /var/tmp/${Region}_totag_snapshots

   # check for an ebs volume and its existence. if the ebs
   # volume does not exist set the tag key values to the defaults
   # (see comments in script header/comments)
   for snap in `cat /var/tmp/${Region}_totag_snapshots`
   do
      # grab the snapshot's volume id...
      for vol in `aws ec2 --region ${Region} --output text describe-snapshots --snapshot-ids ${snap} --query 'Snapshots[].[VolumeId]'`
      do
 	# check for the volume's existence
        aws ec2 --region ${Region} --output text describe-volumes --volume-ids ${vol} > /dev/null 2>&1
        if [ $? = 0 ]
	then
	   # create the tag list...
	   aws ec2 --region ${Region} --output text describe-volumes --volume-ids ${vol} --query 'Volumes[].[Tags]' | awk -F"	" '{print $1"|"$2}' | sed "s/ //" > /var/tmp/${vol}_tags
	   # get the tag keys and their values and assign them to the snapshot...
	   for tag in `cat /var/tmp/${vol}_tags`
	   do
	      key=`echo ${tag} | awk -F"|" '{print $1}'`
	      value=`echo ${tag} | awk -F"|" '{print $2}'`
	      aws ec2 --region ${Region} create-tags --resources ${snap} --tags "Key=${key},Value=${value}"
	      echo "aws ec2 --region ${Region} create-tags --resources ${snap} --tags Key=${key},Value=${value}"
	   done
	   # clean up the volume tag file...
	   rm /var/tmp/${vol}_tags
	else
	   # volume not found... go to defaults
	   aws ec2 --region ${Region} create-tags --resources ${snap} --tags "Key=<tag_key>,Value=sysops" "Key=Env,Value=stage" "Key=<tag_key>,Value=1234" "Key=Company,Value=company_name" "Key=Function,Value=sysops"
	   echo "aws ec2 --region ${Region} create-tags --resources ${snap} --tags Key=<tag_key>,Value=sysops Key=Env,Value=stage Key=<tag_key>,Value=1234 Key=Company,Value=company_name Key=Function,Value=sysops"
	fi
      done
   done
}

# clean up after ourselves...
function clean_up {
   # look for the file in /var/tmp. email it and delete it if found...
   ls -1 /var/tmp/${Region}_totag_snapshots > /dev/null 2>&1
   if [ $? = 0 ]
   then
      # email what we just did...
      [[ -s /var/tmp/${Region}_totag_snapshots ]] && mail -s "${Region}:Snapshots tagged" your.email@domain.com < /var/tmp/${Region}_totag_snapshots
      # remove the file...
      rm /var/tmp/${Region}_totag_snapshots
   fi
}
# main...
# usage and execution of functions...
case ${1} in
   -h|--help)
	echo "
`basename $0` [AWS_Region]
"
	exit 1
	;;
   -?|--?)
	echo "
   Usage: `basename $0` [AWS_Region]
"
	exit 1
	;;
   "")
	echo "
   Usage: `basename $0` [AWS_Region]
"
	exit 1
	;;
   us-east-1)
	tag_snaps
	clean_up
	;;
   us-west-2)
	tag_snaps
	clean_up
	;;
   *)
	echo "
   Usage: `basename $0` [AWS_Region]
"
	exit 1
	;;
esac
exit 0
