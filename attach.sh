curDir=`pwd`
networkid=$(cat networkid)

geth attach ipc:/$curDir/cluster$networkid/data/0$1/geth.ipc
