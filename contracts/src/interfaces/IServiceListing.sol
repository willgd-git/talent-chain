// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title IServiceListing Interface
/// @notice Interface for reading service data from the ServiceListing contract
interface IServiceListing {
    /// @notice Retrieves service information by serviceId
    /// @param serviceId The ID of the service to query
    /// @return serviceIdOut The ID of the service (should match serviceId)
    /// @return provider The provider address of the service
    /// @return price The price of the service
    /// @return ipfsHash The IPFS hash containing information regarding the services
    /// @return isActive True if the service is active, false otherwise
    function services(uint256 serviceId) external view returns (
        uint256 serviceIdOut,
        address provider,
        uint256 price,
        string memory ipfsHash,
        bool isActive
    );
}
