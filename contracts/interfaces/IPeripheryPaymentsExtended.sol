// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.5;

import '@dragonswap/v2-periphery/contracts/interfaces/IPeripheryPayments.sol';

/// @title Periphery Payments Extended
/// @notice Functions to ease deposits and withdrawals of SEI and tokens
interface IPeripheryPaymentsExtended is IPeripheryPayments {
    /// @notice Unwraps the contract's WSEI balance and sends it to msg.sender as SEI.
    /// @dev The amountMinimum parameter prevents malicious contracts from stealing WSEI from users.
    /// @param amountMinimum The minimum amount of WSEI to unwrap
    function unwrapWSEI(uint256 amountMinimum) external payable;

    /// @notice Wraps the contract's SEI balance into WSEI
    /// @dev The resulting WSEI is custodied by the router, thus will require further distribution
    /// @param value The amount of SEI to wrap
    function wrapSEI(uint256 value) external payable;

    /// @notice Transfers the full amount of a token held by this contract to msg.sender
    /// @dev The amountMinimum parameter prevents malicious contracts from stealing the token from users
    /// @param token The contract address of the token which will be transferred to msg.sender
    /// @param amountMinimum The minimum amount of token required for a transfer
    function sweepToken(address token, uint256 amountMinimum) external payable;

    /// @notice Transfers the specified amount of a token from the msg.sender to address(this)
    /// @param token The token to pull
    /// @param value The amount to pay
    function pull(address token, uint256 value) external payable;
}
