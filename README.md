# Course Project

## Prerequisites

Here's the software you need to run the program:
+ go-ethereum (>= 1.7.3)
+ Solidity (>= 0.4.18)
+ Truffle (>= 4.0.1)

## How to set up the private Ethereum network

+ Start the bootnode

In the main directory, run the following command:

```
./boot.sh
```

+ Start the member nodes (the script will start 3 nodes):
```
./run.sh
```

When you start the member nodes, you can attach to any node instance and start to mine.

## How to migrate the smart contracts

You can choose to migrate the contracts to the private network or to the *Ganache* test network:
```
truffle migrate --network <private/ganache>
```

## How to test the smart contracts

You can choose to test the contracts to the private network or to the *Ganache* test network. Before you run the test on the private network, remember to create and unlock 10 accounts in the node that you connect to. Besides, make sure that you have mined some *ether* in each account.

```
truffle test --network <private/ganache>
```

## Build and test environment

+ Build and test: 
```
ubuntu 16.04
```
