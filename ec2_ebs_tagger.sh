#!/bin/bash
#
# Title: ec2_ebs_tagger.sh
#
# Description: ebs_tagger.sh is used to tag EC2-related infrastructure
# It looks for EBS volumes without the tag keys, <tag_key> or <tag_key>, and uses the
# tags from the EC2 instance the volume was created. If the EC2 instance no
# longer exists the tag values assigned are <tag_key>:<tag_value>,
# Env:dev, <tag_key>:1234.
#
# Usage: ec2_ebs_tagger.sh [AWS_Region]
#
# Requirements:
#   - Root level access to a UNIX/Linux system. Sudo will do. Or an EC2 instance
#     with an IAM role that grants EC2, full access
#   - AWS CLI (pip install awscli)
#   - AWS CLI in root's/superuser's path
#   - Proper AWS IAM role or user with EC2 full access
#   - Python 2.7.10 or 3.5.2
################################################################################# 
# variables...
export PATH=${PATH}:/usr/local/bin:/usr/local/admin/bin
Region=${1}

# function to work through the volume tagging process...
function tag_vols {
   # what volumes are missing the <tag_key> tag key...
   aws ec2 --region ${Region} --output text describe-volumes --query 'Volumes[?!not_null(Tags[?Key == `<tag_key>`].Value)] | [].[VolumeId]' > /var/tmp/${Region}_totag_volumes_nosort
   # what volumes are missing the <tag_key> tag key. this could provide duplicate volume ids in the file. do i care? it all has to be tagged... <shrug>
   aws ec2 --region ${Region} --output text describe-volumes --query 'Volumes[?!not_null(Tags[?Key == `<tag_key>`].Value)] | [].[VolumeId]' >> /var/tmp/${Region}_totag_volumes_nosort

   # do a unique sort on the file so that a volume id only shows up once...
   sort -u /var/tmp/${Region}_totag_volumes_nosort > /var/tmp/${Region}_totag_volumes

   # check for an ec2 instance and its existence. if the ec2 instance
   # does not exist set the tag key values to the defaults
   # (see comments in script header/comments)
   for vol in `cat /var/tmp/${Region}_totag_volumes`
   do
      # grab the volume's instance id. does it exist? if so, continue. if not, use defaults
      aws ec2 --region ${Region} --output text describe-instances --filters "Name=block-device-mapping.volume-id,Values=${vol}" --query 'Reservations[].Instances[][InstanceId]' | egrep "i-[a-z,0-9]" > /dev/null 2>&1
      if [ $? = 0 ]
      then
	 for inst in `aws ec2 --region ${Region} --output text describe-instances --filters "Name=block-device-mapping.volume-id,Values=${vol}" --query 'Reservations[].Instances[][InstanceId]'`
	 do
	    # create the instance's tag list...
	    aws ec2 --region ${Region} --output text describe-instances --instance-ids ${inst} --query 'Reservations[].Instances[].[Tags]' | awk -F"	" '{print $1"|"$2}' | sed "s/ //" > /var/tmp/${Region}_${vol}_tags

	    # user /var/tmp/${Region}_${vol}_tags to get tag keys and their values. assign the values to the keys...
	    for tag in `cat /var/tmp/${Region}_${vol}_tags`
	    do
	       key=`echo ${tag} | awk -F"|" '{print $1}'`
	       value=`echo ${tag} | awk -F"|" '{print $2}'`
	       aws ec2 --region ${Region} create-tags --resources ${vol} --tags "Key=${key},Value=${value}"
	       echo "aws ec2 --region ${Region} create-tags --resources ${vol} --tags Key=${key},Value=${value}"
	    done
	    # clean up the volume tag file...
	    rm /var/tmp/${Region}_${vol}_tags
	  done
      else
	   # instance not found. go with defaults...
	   aws ec2 --region ${Region} create-tags --resources ${vol} --tags "Key=<tag_key>,Value=sysops" "Key=Env,Value=stage" "Key=<tag_key>,Value=1234" "Key=Company,Value=company_name" "Key=Function,Value=sysops"
	   echo "aws ec2 --region ${Region} create-tags --resources ${vol} --tags Key=<tag_key>,Value=sysops Key=Env,Value=stage Key=<tag_key>,Value=1234 Key=Company,Value=company_name Key=Function,Value=sysops"
       fi
   done
}

# clean up after ourselves...
function clean_up {
   # look for the file in /var/tmp. if present - good. check for contents and email it then delete it...
   ls -1 /var/tmp/${Region}_totag_volumes > /dev/null 2>&1
   if [ $? = 0 ]
   then
      # email what we just did...
      [[ -s /var/tmp/${Region}_totag_volumes ]]  && mail -s "${Region}: Volumes tagged" your.email@domain.com < /var/tmp/${Region}_totag_volumes
      # remove the file...
      rm /var/tmp/${Region}_totag_volumes
   fi
}

# main...
# usage and code execution...
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
   us-east-1)
	tag_vols
	clean_up
	;;
   us-west-2)
	tag_vols
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
