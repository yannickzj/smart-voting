# !/bin/bash

# sets up a local ethereum network cluster of nodes
root=$1
network_id=$2
dir=$root/cluster$network_id
mkdir -p $dir/data
mkdir -p $dir/log
N=$3
pwddir=$4
bootnodes=$5

GETH=geth

for i in `seq 1 $N`
do
  id=`printf "%02d" $i`
  datadir=$dir/data/$id
  mkdir -p $datadir
  port=303$id
  rpcport=81$id
  pwd=$pwddir/$id.pwd

  if [ -z "$(ls -A $datadir)" ];
  then
	echo create an account for node $id
	$GETH --datadir $datadir --password $pwd account new
	$GETH --datadir $datadir init genesis.json
  fi

  echo start member node $id
  $GETH --datadir $datadir --networkid $network_id --port $port --rpc --rpcport $rpcport --rpcaddr 127.0.0.1 --rpccorsdomain "*" --rpcapi "eth,net,web3,personal" --bootnodes $bootnodes 2>> $dir/log/$id.log &

done
