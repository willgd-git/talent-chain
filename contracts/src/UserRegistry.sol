// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interfaces/IUserRegistry.sol";

/// @title User Registry Contract for TalentChain
/// @notice Allows users to register on-chain with profiles stored on IPFS. Events are indexed by The Graph.
/// @dev Stores IPFS hashes on-chain to reference off-chain user data.
contract UserRegistry is IUserRegistry {
    /// @notice Maps user addresses to their IPFS profile hashes
    mapping(address => string) public userProfiles;

    /// @notice Emitted when a user registers
    /// @param userAddress The address of the user who registered
    /// @param ipfsHash The IPFS hash of the user's profile
    event UserRegistered(address indexed userAddress, string ipfsHash);

    /// @notice Emitted when a user updates their profile
    /// @param userAddress The address of the user who updated their profile
    /// @param oldIpfsHash The previous IPFS hash of the user's profile
    /// @param newIpfsHash The new IPFS hash of the user's profile
    event UserProfileUpdated(address indexed userAddress, string oldIpfsHash, string newIpfsHash);

    /// @notice Register the caller as a user with their IPFS profile
    /// @param _ipfsHash The IPFS hash of the user's profile JSON
    /// @dev Reverts if the user is already registered or if the IPFS hash is empty
    function registerUser(string memory _ipfsHash) external override {
        require(bytes(_ipfsHash).length > 0, "IPFS hash cannot be empty");
        require(bytes(userProfiles[msg.sender]).length == 0, "User already registered");

        userProfiles[msg.sender] = _ipfsHash;
        emit UserRegistered(msg.sender, _ipfsHash);
    }

    /// @notice Update the IPFS hash for an existing user profile
    /// @param _newIpfsHash The new IPFS hash of the user's profile JSON
    /// @dev Reverts if the user is not already registered or if the IPFS hash is empty
    function updateUserProfile(string memory _newIpfsHash) external {
        require(bytes(_newIpfsHash).length > 0, "IPFS hash cannot be empty");
        require(bytes(userProfiles[msg.sender]).length > 0, "User not registered");

        string memory oldIpfsHash = userProfiles[msg.sender];
        userProfiles[msg.sender] = _newIpfsHash;

        emit UserProfileUpdated(msg.sender, oldIpfsHash, _newIpfsHash);
    }

    /// @notice Check if a user is registered
    /// @param _user The address of the user to check
    /// @return bool indicating if the user is registered
    function isUserRegistered(address _user) external view override returns (bool) {
        return bytes(userProfiles[_user]).length > 0;
    }
}
