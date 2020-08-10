#!/bin/bash

for i in 1 2 4 8 16 32 64 128 256
do
	echo "##### [ $i ] ##################################################################################"
	hive -f 6-1_CNTRY_IP_RANGE_EXTENT_NUMT_part.HQL --hivevar VAR_OCTET3=$i 
done	

echo "##### [ etc ] ##################################################################################"
hive -f 6-1_CNTRY_IP_RANGE_EXTENT_NUMT_etc.HQL

echo "##### [ Done ] ##################################################################################"