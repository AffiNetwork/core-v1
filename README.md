# Affi Network Core Contracts

This repo contains the Affi network core contract, currently under active development.

## Testing

```shell
forge test -vv
```

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
