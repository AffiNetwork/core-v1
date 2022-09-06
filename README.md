# Affi Network Core Contracts

## Testing

```shell
forge test -vv
```

## Stack

## Foundry

## Solmate

## Security testing

### Slither

```shell

 slither . --config-file slither.config.json
```

### Mythril

```shell
docker run --rm -v ${PWD}:/code mythril/myth:latest a /code/src/CampaignFactory.sol --solc-json  /code/mythril.config.json
```
