// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.5;

import '@dragonswap/v2-periphery/contracts/interfaces/IPeripheryPaymentsWithFee.sol';

import './IPeripheryPaymentsExtended.sol';

/// @title Periphery Payments With Fee Extended
/// @notice Functions to ease deposits and withdrawals of SEI
interface IPeripheryPaymentsWithFeeExtended is IPeripheryPaymentsExtended, IPeripheryPaymentsWithFee {
    /// @notice Unwraps the contract's WSEI balance and sends it to msg.sender as SEI, with a percentage between
    /// 0 (exclusive), and 1 (inclusive) going to feeRecipient
    /// @dev The amountMinimum parameter prevents malicious contracts from stealing WSEI from users.
    function unwrapWSEIWithFee(
        uint256 amountMinimum,
        uint256 feeBips,
        address feeRecipient
    ) external payable;

    /// @notice Transfers the full amount of a token held by this contract to msg.sender, with a percentage between
    /// 0 (exclusive) and 1 (inclusive) going to feeRecipient
    /// @dev The amountMinimum parameter prevents malicious contracts from stealing the token from users
    function sweepTokenWithFee(
        address token,
        uint256 amountMinimum,
        uint256 feeBips,
        address feeRecipient
    ) external payable;
}
