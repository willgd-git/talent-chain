// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interfaces/IUserRegistry.sol";

/// @title User Registry Contract for TalentChain
/// @notice Allows users to register on-chain. Events are indexed by The Graph.
/// @dev Does not store IPFS hashes on-chain. Minimal functionality to demonstrate testing pattern.
contract UserRegistry is IUserRegistry {
    /// @notice Maps user addresses to their registration status
    mapping(address => bool) public isUserRegistered;

    /// @notice Emitted when a user registers
    /// @param userAddress The address of the user who registered
    event UserRegistered(address indexed userAddress);

    /// @notice Register the caller as a user
    /// @dev Reverts if the user is already registered
    function registerUser() external {
        require(!isUserRegistered[msg.sender], "User already registered");
        isUserRegistered[msg.sender] = true;
        emit UserRegistered(msg.sender);
    }
}
