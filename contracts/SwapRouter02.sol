// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity =0.7.6;
pragma abicoder v2;

import '@dragonswap/v2-periphery/contracts/base/SelfPermit.sol';
import '@dragonswap/v2-periphery/contracts/base/PeripheryImmutableState.sol';

import './interfaces/ISwapRouter02.sol';
import './V1SwapRouter.sol';
import './V2SwapRouter.sol';
import './base/ApproveAndCall.sol';
import './base/MulticallExtended.sol';

/// @title Dragonswap V1 and V2 Swap Router
contract SwapRouter02 is ISwapRouter02, V1SwapRouter, V2SwapRouter, ApproveAndCall, MulticallExtended, SelfPermit {
    constructor(
        address _factoryV1,
        address factoryV2,
        address _positionManager,
        address _WSEI
    ) ImmutableState(_factoryV1, _positionManager) PeripheryImmutableState(factoryV2, _WSEI) {}
}
