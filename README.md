# Affi Network Core Contracts

This repo contains the Affi network core contract, currently under active development.

## Testing

```shell
forge test -vv
```

to get code coverage info this foundry add a way to filter specfic target use this.

```
 forge coverage | egrep 'CampaignFactory.sol|CampaignContract.sol'
```

current coverage is at 100%

## Stack

- foundry
- solmate
- openzeppelin

## Security testing

### Slither

```shell

 slither . --config-file slither.config.json
```

### Mythril

```shell
docker run --rm -v ${PWD}:/code mythril/myth:latest a /code/src/CampaignFactory.sol --solc-json  /code/mythril.config.json
```

## Foundry

## Deployment

```

forge script script/CampaignFactory.s.sol:DeployFactory --rpc-url http://127.0.0.1:8545 --broadcast --sender 0xf39fd6e51aad88f6f4ce6ab8827279cfffb92266 --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80
```

verification

```

 forge script script/CampaignFactory.s.sol:DeployFactory --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80  \
    --etherscan-api-key polygonscan_key \
    --verify
```

##

```
 cast call  0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0  "campaigns(uint256)(address)" 0  --rpc-url http://127.0.0.1:8545 --from 0xf39fd6e51aad88f6f4ce6ab8827279cfffb92266 --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80
```
