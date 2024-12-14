// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title IUserRegistry Interface
/// @notice Interface to check if a user is registered in the UserRegistry contract
interface IUserRegistry {
    /// @notice Checks if a given user address is registered
    /// @param userAddress The address to check
    /// @return registered True if registered, false otherwise
    function isUserRegistered(address userAddress) external view returns (bool registered);
}
