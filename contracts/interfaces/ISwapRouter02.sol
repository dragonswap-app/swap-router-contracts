// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.5;
pragma abicoder v2;

import '@dragonswap/v2-periphery/contracts/interfaces/ISelfPermit.sol';

import './IV1SwapRouter.sol';
import './IV2SwapRouter.sol';
import './IApproveAndCall.sol';
import './IMulticallExtended.sol';

/// @title Router token swapping functionality
interface ISwapRouter02 is IV1SwapRouter, IV2SwapRouter, IApproveAndCall, IMulticallExtended, ISelfPermit {

}
