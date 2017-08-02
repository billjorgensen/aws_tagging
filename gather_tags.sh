#!/bin/bash
export PATH=${PATH}:/usr/local:/usr/local/bin:/usr/local/admin/bin
BinDir=/usr/local/admin/bin
Region=${1}
Resource=${2}

# function to get tag information
function gather_tag_info {
   for res in `cat ${BinDir}/${Region}_${Resource}_ids`
   do
      for keys in `cat ${BinDir}/ordered_west2_tag_keys`
      do
         Result=`aws ec2 --region ${Region} --output text describe-tags --filters "Name=key,Values=${keys}" "Name=resource-id,Values=${res}"`
         if [ "X${Result}" = "X" ]
         then
            echo ",Null"
         else
            echo ${Result} | awk '{print ","$5}'
         fi
      done >> /var/tmp/${res}_keytags

      # create the resource id csv file
      for tag in `cat /var/tmp/${res}_keytags`
      do
         echo -n "${tag}"
      done | sed "s/^\,/${res}\,/" >> /var/tmp/${res}_keytags.csv 

      # remove the raw tag file and leave csv...
      rm /var/tmp/${res}_keytags
   done
}

# function to compile results in a csv file
function make_csv {
   # make the csv header from west-2 tags
   for keys in `cat ${BinDir}/ordered_west2_tag_keys`
   do
      echo -n ",$keys"
   done | sed "s/^\,Name/Resource ID\,Name/" > /var/tmp/${Region}_${Resource}_tagkeys.csv

   # append ${Region}_tagkeys.csv with the resource id csv files
   for res in `cat ${Region}_${Resource}_ids`
   do
      cat /var/tmp/${res}_keytags.csv >> /var/tmp/${Region}_${Resource}_tagkeys.csv
      rm /var/tmp/${res}_keytags.csv
   done
}

# main...
case ${1} in
   -h|--help)
     echo "
  Usage: `basename $0` [AWS_region] [AWS_resource]
"
      exit 1
      ;;
   -?|--?)
      echo "
  Usage: `basename $0` [AWS_region] [AWS_resource]
"
      exit 1
      ;;
   us-west-2)
      gather_tag_info
      make_csv
      ;;
   us-east-1) 
      gather_tag_info
      make_csv
      ;;
   *)
      echo "
  Usage: `basename $0` [AWS_region] [AWS_resource]
"
      exit 1
      ;;
esac
exit 0
