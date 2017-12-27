# !/bin/bash

root="."
network_id=$(cat networkid)
N=3
pwddir=pwd
bootnodes=$(cat enodeboot$network_id)

./gethcluster.sh $root $network_id $N $pwddir $bootnodes
