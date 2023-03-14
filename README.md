# Affi Network Core Contracts

[![banner](./assets/banner.png)](https://affi.network)


This repo contains the very first version of the Affi Network Core contract. A step towards zero ad fraud, result-based affiliate marketing through blockchain medium. 



## Motivation 

Advertisers have been fighting an uphill battle to hook up with publishers on a commission basis for decades. Publisher may exaggerate their traffic, and advertisers may not pay publishers on time. verifying the truth tedious task. Affi Network is a result-based affiliate marketing platform that uses blockchain to verify the truth and pay publishers on time. on top of it it rewawrd buyers with cashback.the smart contract is the core protocol between advertisers and publishers and buyers.

## Design

It contains two main files ```CampaignFactory``` and ```CampaignContract```  the factory is deployed by protocol, and advertisers deploy campaign contracts.

Factory allows creating a campaign backed by either more decentralized ``` DAI``` or less-decentralized stablecoins. On future versions of Affi networks, it is planned to support $AFFI as a commission payment. 


Each campaign contract deployed by the factory contains critical on-chain information about each campaign. 


- ***duration***: there is a hardcoded lock of `30` days to give enough time to the advertiser to react 
- ***contract address***: the target contract to be promised by publishers 
- ***network***: currently supports a large chunk of EVM chains 
- ***cost of acquisition***: the cost per sale 
- ***party shares***: how much cashback and commission are being paid 


Whenever a transaction happens on the target contract address, our automated bot will check for sanity and security checks and call ```sealADeal``` function to pay all parties. 



Core contracts follow a monolith architecture and use no inline assembly and surprises to make auditing more pleasant; even though various gas optimization like proper error reverting and data packing, use gas optimized/audited ERC-20 implementation, and the modern compiler used, the primary design goal was security and simplicity over-optimization. Core contract running primarily on the Polygon network, its relatively affordable to interact with the current contract. 



## Deployed Address : 

### Mumbai testnet : 

- https://mumbai.polygonscan.com/address/0xTBA

### Polygon mainnet:

- https://mumbai.polygonscan.com/address/0xTBA

## Testing

```shell
forge test -vv
```

to get code coverage info this foundry add a way to filter specfic target use this.

```
 forge coverage | egrep 'CampaignFactory.sol|CampaignContract.sol'
```

current coverage is at 100%.

## Stack

- foundry
- solmate

## Security 

### Audit 

- Audit by [Beosin](./assets/Audit-2023-03-10.pdf)
- Audit methods: Formal Verification, Static Analysis, Typical Case Testing 
- Audit hash = [54d798cbce572ecb6568432c95b2a0a8a33a93fc](https://github.com/AffiNetwork/core-v1/commit/54d798cbce572ecb6568432c95b2a0a8a33a93fc)

### Automated security testing

### Slither (static)

```shell

 slither . --config-file slither.config.json
```

### Mythril (dynamic)

```shell
docker run --rm -v ${PWD}:/code mythril/myth:latest a /code/src/CampaignFactory.sol --solc-json  /code/mythril.config.json
```


## Deployment

```

forge script script/CampaignFactory.s.sol:DeployFactory --rpc-url http://127.0.0.1:8545 --broadcast --sender 0xdeployer --private-key 0xkey
```

### Verification

```

 forge script script/CampaignFactory.s.sol:DeployFactory --private-key 0xkey  \
    --etherscan-api-key polygonscan_key \
    --verify
```

### checking deployed contract 

```
 cast call  0xfactory  "campaigns(uint256)(address)" 0  --rpc-url http://127.0.0.1:8545 --from 0xdeployer --private-key 0xkey
```
