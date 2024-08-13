# Dragonswap Swap Router

[![Tests](https://github.com/dragonswap-app/swap-router-contracts/workflows/Tests/badge.svg)](https://github.com/dragonswap-app/swap-router-contracts/actions?query=workflow%3ATests)
[![Lint](https://github.com/dragonswap-app/swap-router-contracts/workflows/Lint/badge.svg)](https://github.com/dragonswap-app/swap-router-contracts/actions?query=workflow%3ALint)

This repository contains smart contracts for swapping on the Dragonswap V1 and V2 protocols.

## Links

- [Audit report](https://github.com/dragonswap-app/v2-core/blob/main/audits/20240801_Paladin_DragonSwapDEX_Final_Report.pdf)

## Local deployment

In order to deploy this code to a local testnet, you should clone this repository and import bytecode imported from artifacts located at
`swap-router-contracts/artifacts/contracts/*/*.json`.
For example:

```typescript
import {
  abi as SWAP_ROUTER_ABI,
  bytecode as SWAP_ROUTER_BYTECODE,
} from './artifacts/contracts/SwapRouter02.sol/SwapRouter02.json'

// deploy the bytecode
```

This will ensure that you are testing against the same bytecode that is deployed to
mainnet and public testnets, and all Dragonswap code will correctly interoperate with
your local deployment.

## Using solidity interfaces

The swap router contract interfaces are available for import into solidity smart contracts.

```solidity
import '@dragonswap/swap-router-contracts/contracts/interfaces/ISwapRouter02.sol';

contract MyContract {
  ISwapRouter02 router;

  function doSomethingWithSwapRouter() {
    // router.exactInput(...);
  }
}

```

## Tests

Some tests use Hardhat mainnet forking and therefore require an archive node.
Either create a `.env` file in the workspace root containing:

```
ARCHIVE_RPC_URL='...'
```

Or set the variable when running tests:

```
export ARCHIVE_RPC_URL='...' && npm run test
```
