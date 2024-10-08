// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Immutable state
/// @notice Functions that return immutable state of the router
interface IImmutableState {
    /// @return Returns the address of the Dragonswap V1 factory
    function factoryV1() external view returns (address);

    /// @return Returns the address of Dragonswap V2 NFT position manager
    function positionManager() external view returns (address);
}
