// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IUserRegistry {
    /// @notice Register the caller as a user with their IPFS profile
    /// @param _ipfsHash The IPFS hash of the user's profile JSON
    function registerUser(string memory _ipfsHash) external;

    /// @notice Check if a user is registered
    /// @param _user The address of the user to check
    /// @return bool indicating if the user is registered
    function isUserRegistered(address _user) external view returns (bool);
}
