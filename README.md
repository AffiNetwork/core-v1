# Affi Network Core Contracts

This repo contains the very first version of the Affi Network Core contract. A step towards zero ad fraud, result-based affiliate marketing through blockchain medium. 

## Design

It contains two main files ```CampaignFactory``` and ```CampaignContract```  the factory is deployed by protocol, and advertisers deploy campaign contracts.

Factory allows creating a campaign backed by either more decentralized ``` DAI``` or less-decentralized stablecoins. On future versions of Affi networks, it is planned to support $AFFI as a commission payment. 

Each campaign contract deployed by the factory contains critical on-chain information about each campaign. 

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

## Security testing

### Slither

```shell

 slither . --config-file slither.config.json
```

### Mythril

```shell
docker run --rm -v ${PWD}:/code mythril/myth:latest a /code/src/CampaignFactory.sol --solc-json  /code/mythril.config.json
```


## Deployment

```

forge script script/CampaignFactory.s.sol:DeployFactory --rpc-url http://127.0.0.1:8545 --broadcast --sender 0xdeployer --private-key 0xkey
```

### verification

```

 forge script script/CampaignFactory.s.sol:DeployFactory --private-key 0xkey  \
    --etherscan-api-key polygonscan_key \
    --verify
```

### checking deployed contract 

```
 cast call  0xfactory  "campaigns(uint256)(address)" 0  --rpc-url http://127.0.0.1:8545 --from 0xdeployer --private-key 0xkey
```
