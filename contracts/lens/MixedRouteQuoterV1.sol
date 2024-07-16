// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity =0.7.6;
pragma abicoder v2;

import '@dragonswap/v2-periphery/contracts/base/PeripheryImmutableState.sol';
import '@dragonswap/v2-core/contracts/libraries/SafeCast.sol';
import '@dragonswap/v2-core/contracts/libraries/TickMath.sol';
import '@dragonswap/v2-core/contracts/interfaces/IDragonswapV2Pool.sol';
import '@dragonswap/v2-core/contracts/interfaces/callback/IDragonswapV2SwapCallback.sol';
import '@dragonswap/v2-periphery/contracts/libraries/Path.sol';
import '@dragonswap/v2-periphery/contracts/libraries/PoolAddress.sol';
import '@dragonswap/v2-periphery/contracts/libraries/CallbackValidation.sol';

import '../interfaces/IMixedRouteQuoterV1.sol';
import '../libraries/PoolTicksCounter.sol';
import '../libraries/DragonswapLibrary.sol';

/// @title Provides on chain quotes for V2, V1, and MixedRoute exact input swaps
/// @notice Allows getting the expected amount out for a given swap without executing the swap
/// @notice Does not support exact output swaps since using the contract balance between exactOut swaps is not supported
/// @dev These functions are not gas efficient and should _not_ be called on chain. Instead, optimistically execute
/// the swap and check the amounts in the callback.
contract MixedRouteQuoterV1 is IMixedRouteQuoterV1, IDragonswapV2SwapCallback, PeripheryImmutableState {
    using Path for bytes;
    using SafeCast for uint256;
    using PoolTicksCounter for IDragonswapV2Pool;
    address public immutable factoryV1;
    /// @dev Value to bit mask with path fee to determine if V1 or V2 route
    // max V2 fee:           000011110100001001000000 (24 bits)
    // mask:       1 << 23 = 100000000000000000000000 = decimal value 8388608
    uint24 private constant flagBitmask = 8388608;

    /// @dev Transient storage variable used to check a safety condition in exact output swaps.
    uint256 private amountOutCached;

    constructor(
        address _factory,
        address _factoryV1,
        address _WSEI
    ) PeripheryImmutableState(_factory, _WSEI) {
        factoryV1 = _factoryV1;
    }

    function getPool(
        address tokenA,
        address tokenB,
        uint24 fee
    ) private view returns (IDragonswapV2Pool) {
        return IDragonswapV2Pool(PoolAddress.computeAddress(factory, PoolAddress.getPoolKey(tokenA, tokenB, fee)));
    }

    /// @dev Given an amountIn, fetch the reserves of the V1 pair and get the amountOut
    function getPairAmountOut(
        uint256 amountIn,
        address tokenIn,
        address tokenOut
    ) private view returns (uint256) {
        (uint256 reserveIn, uint256 reserveOut) = DragonswapLibrary.getReserves(factoryV1, tokenIn, tokenOut);
        return DragonswapLibrary.getAmountOut(amountIn, reserveIn, reserveOut);
    }

    /// @inheritdoc IDragonswapV2SwapCallback
    function dragonswapV2SwapCallback(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes memory path
    ) external view override {
        require(amount0Delta > 0 || amount1Delta > 0); // swaps entirely within 0-liquidity regions are not supported
        (address tokenIn, address tokenOut, uint24 fee) = path.decodeFirstPool();
        CallbackValidation.verifyCallback(factory, tokenIn, tokenOut, fee);

        (bool isExactInput, uint256 amountReceived) =
            amount0Delta > 0
                ? (tokenIn < tokenOut, uint256(-amount1Delta))
                : (tokenOut < tokenIn, uint256(-amount0Delta));

        IDragonswapV2Pool pool = getPool(tokenIn, tokenOut, fee);
        (uint160 v2SqrtPriceX96After, int24 tickAfter, , , , , ) = pool.slot0();

        if (isExactInput) {
            assembly {
                let ptr := mload(0x40)
                mstore(ptr, amountReceived)
                mstore(add(ptr, 0x20), v2SqrtPriceX96After)
                mstore(add(ptr, 0x40), tickAfter)
                revert(ptr, 0x60)
            }
        } else {
            /// since we don't support exactOutput, revert here
            revert('Exact output quote not supported');
        }
    }

    /// @dev Parses a revert reason that should contain the numeric quote
    function parseRevertReason(bytes memory reason)
        private
        pure
        returns (
            uint256 amount,
            uint160 sqrtPriceX96After,
            int24 tickAfter
        )
    {
        if (reason.length != 0x60) {
            if (reason.length < 0x44) revert('Unexpected error');
            assembly {
                reason := add(reason, 0x04)
            }
            revert(abi.decode(reason, (string)));
        }
        return abi.decode(reason, (uint256, uint160, int24));
    }

    function handleV2Revert(
        bytes memory reason,
        IDragonswapV2Pool pool,
        uint256 gasEstimate
    )
        private
        view
        returns (
            uint256 amount,
            uint160 sqrtPriceX96After,
            uint32 initializedTicksCrossed,
            uint256
        )
    {
        int24 tickBefore;
        int24 tickAfter;
        (, tickBefore, , , , , ) = pool.slot0();
        (amount, sqrtPriceX96After, tickAfter) = parseRevertReason(reason);

        initializedTicksCrossed = pool.countInitializedTicksCrossed(tickBefore, tickAfter);

        return (amount, sqrtPriceX96After, initializedTicksCrossed, gasEstimate);
    }

    /// @dev Fetch an exactIn quote for a V2 Pool on chain
    function quoteExactInputSingleV2(QuoteExactInputSingleV2Params memory params)
        public
        override
        returns (
            uint256 amountOut,
            uint160 sqrtPriceX96After,
            uint32 initializedTicksCrossed,
            uint256 gasEstimate
        )
    {
        bool zeroForOne = params.tokenIn < params.tokenOut;
        IDragonswapV2Pool pool = getPool(params.tokenIn, params.tokenOut, params.fee);

        uint256 gasBefore = gasleft();
        try
            pool.swap(
                address(this), // address(0) might cause issues with some tokens
                zeroForOne,
                params.amountIn.toInt256(),
                params.sqrtPriceLimitX96 == 0
                    ? (zeroForOne ? TickMath.MIN_SQRT_RATIO + 1 : TickMath.MAX_SQRT_RATIO - 1)
                    : params.sqrtPriceLimitX96,
                abi.encodePacked(params.tokenIn, params.fee, params.tokenOut)
            )
        {} catch (bytes memory reason) {
            gasEstimate = gasBefore - gasleft();
            return handleV2Revert(reason, pool, gasEstimate);
        }
    }

    /// @dev Fetch an exactIn quote for a V1 pair on chain
    function quoteExactInputSingleV1(QuoteExactInputSingleV1Params memory params)
        public
        view
        override
        returns (uint256 amountOut)
    {
        amountOut = getPairAmountOut(params.amountIn, params.tokenIn, params.tokenOut);
    }

    /// @dev Get the quote for an exactIn swap between an array of V1 and/or V2 pools
    /// @notice To encode a V1 pair within the path, use 0x800000 (hex value of 8388608) for the fee between the two token addresses
    function quoteExactInput(bytes memory path, uint256 amountIn)
        public
        override
        returns (
            uint256 amountOut,
            uint160[] memory v2SqrtPriceX96AfterList,
            uint32[] memory v2InitializedTicksCrossedList,
            uint256 v2SwapGasEstimate
        )
    {
        v2SqrtPriceX96AfterList = new uint160[](path.numPools());
        v2InitializedTicksCrossedList = new uint32[](path.numPools());

        uint256 i = 0;
        while (true) {
            (address tokenIn, address tokenOut, uint24 fee) = path.decodeFirstPool();

            if (fee & flagBitmask != 0) {
                amountIn = quoteExactInputSingleV1(
                    QuoteExactInputSingleV1Params({tokenIn: tokenIn, tokenOut: tokenOut, amountIn: amountIn})
                );
            } else {
                /// the outputs of prior swaps become the inputs to subsequent ones
                (
                    uint256 _amountOut,
                    uint160 _sqrtPriceX96After,
                    uint32 _initializedTicksCrossed,
                    uint256 _gasEstimate
                ) =
                    quoteExactInputSingleV2(
                        QuoteExactInputSingleV2Params({
                            tokenIn: tokenIn,
                            tokenOut: tokenOut,
                            fee: fee,
                            amountIn: amountIn,
                            sqrtPriceLimitX96: 0
                        })
                    );
                v2SqrtPriceX96AfterList[i] = _sqrtPriceX96After;
                v2InitializedTicksCrossedList[i] = _initializedTicksCrossed;
                v2SwapGasEstimate += _gasEstimate;
                amountIn = _amountOut;
            }
            i++;

            /// decide whether to continue or terminate
            if (path.hasMultiplePools()) {
                path = path.skipToken();
            } else {
                return (amountIn, v2SqrtPriceX96AfterList, v2InitializedTicksCrossedList, v2SwapGasEstimate);
            }
        }
    }
}
