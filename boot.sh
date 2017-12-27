# !/bin/bash

root="."
network_id=$(cat networkid)
pwddir=pwd

dir=$root/cluster$network_id
GETH=geth
bootdir=$dir/boot
ip_addr=127.0.0.1

mkdir -p $bootdir

if [ -z "$(ls -A $bootdir)" ];
then
	echo create an account for bootnode
	$GETH --datadir $bootdir --password $pwddir/00.pwd account new
	$GETH --datadir $bootdir init genesis.json
fi

if [ -z "$(ls -A . | grep enodeboot$network_id)" ];
then
	eth="$GETH --datadir $bootdir --networkid $network_id --port 30300"
	cmd="$eth js <(echo 'console.log(admin.nodeInfo.enode); exit();') "
	bash -c "$cmd" 2>/dev/null |grep enode | perl -pe "s/\[\:\:\]/$ip_addr/g" | tee > enodeboot$network_id
fi

echo start bootnode
$GETH --datadir $bootdir --networkid $network_id --port 30300 --rpc --rpcport 8545 --rpcaddr 127.0.0.1 --rpccorsdomain "*" --rpcapi "eth,net,web3,personal" console #--mine --minerthreads 5 console

