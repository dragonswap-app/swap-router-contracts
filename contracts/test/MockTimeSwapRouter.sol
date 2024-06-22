// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.7.6;
pragma abicoder v2;

import '../SwapRouter02.sol';

contract MockTimeSwapRouter02 is SwapRouter02 {
    uint256 time;

    constructor(
        address _factoryV1,
        address factoryV2,
        address _positionManager,
        address _WSEI
    ) SwapRouter02(_factoryV1, factoryV2, _positionManager, _WSEI) {}

    function _blockTimestamp() internal view override returns (uint256) {
        return time;
    }

    function setTime(uint256 _time) external {
        time = _time;
    }
}
