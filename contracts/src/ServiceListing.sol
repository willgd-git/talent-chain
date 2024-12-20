// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interfaces/IUserRegistry.sol";
import "./interfaces/IServiceListing.sol";

/// @title Service Listing Contract for TalentChain
/// @notice Allows service providers to list services with metadata stored on IPFS.
/// @dev Integrates with UserRegistry to ensure that only registered providers can create or modify services.
contract ServiceListing is IServiceListing {
    /// @notice Structure holding service info
    struct Service {
        uint256 serviceId;
        address provider;
        uint256 price;
        string ipfsHash;
        bool isActive;
    }

    /// @notice Mapping of serviceId to Service struct
    mapping(uint256 => Service) public services;

    /// @notice Tracks the next service ID to assign
    uint256 public nextServiceId;

    /// @notice Address of the UserRegistry contract
    IUserRegistry public userRegistry;
    
    /// @notice Owner address for administrative functions like setting userRegistry
    address public owner;

    /// @notice Emitted when UserRegistry contract has been set
    /// @param userRegistryAddr The address of UserRegistry contract
    event UserRegistrySet(address userRegistryAddr);

    /// @notice Emitted when a new service is created
    /// @param serviceId The ID of the created service
    /// @param provider The provider who created the service
    /// @param price The price of the service
    /// @param ipfsHash The IPFS hash of the service metadata
    event ServiceCreated(uint256 indexed serviceId, address indexed provider, uint256 price, string ipfsHash);

    /// @notice Emitted when a service's price or metadata is updated
    /// @param serviceId The ID of the service updated
    /// @param newPrice The new price of the service
    /// @param newIpfsHash The new IPFS hash of the service metadata
    event ServiceUpdated(uint256 indexed serviceId, uint256 newPrice, string newIpfsHash);

    /// @notice Emitted when a service is deactivated
    /// @param serviceId The ID of the service deactivated
    event ServiceDeactivated(uint256 indexed serviceId);

    /// @notice Emitted when a service is reactivated
    /// @param serviceId The ID of the service reactivated
    event ServiceReactivated(uint256 indexed serviceId);

    /// @notice Constructor sets the owner
    constructor() {
        owner = msg.sender;
    }

    /// @notice Sets the UserRegistry contract after deployment
    /// @param userRegistryAddr The address of the UserRegistry contract
    function setUserRegistry(address userRegistryAddr) external onlyOwner {
        require(userRegistryAddr != address(0), "Invalid UserRegistry address");
        userRegistry = IUserRegistry(userRegistryAddr);

        emit UserRegistrySet(userRegistryAddr);
    }

    /// @notice Modifier to ensure the caller is the contract owner
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner");
        _;
    }

    /// @notice Modifier to ensure the caller is registered as a provider
    modifier registeredProvider() {
        require(userRegistry.isUserRegistered(msg.sender), "Provider not registered");
        _;
    }

    /// @notice Modifier to ensure only the service provider can modify the service
    /// @param serviceId The ID of the service
    modifier onlyProvider(uint256 serviceId) {
        require(services[serviceId].serviceId == serviceId, "Service does not exist");
        require(services[serviceId].provider == msg.sender, "Only provider can modify");
        _;
    }

    /// @notice Creates a new service, must be a registered provider and price > 0
    /// @param price The price of the service
    /// @param ipfsHash The IPFS hash of the service metadata
    /// @return serviceId The ID of the newly created service
    function createService(uint256 price, string memory ipfsHash) external registeredProvider returns (uint256 serviceId) {
        require(price > 0, "Price must be greater than zero");
        require(bytes(ipfsHash).length > 0, "IPFS hash cannot be empty");

        serviceId = ++nextServiceId;
        services[serviceId] = Service({
            serviceId: serviceId,
            provider: msg.sender,
            price: price,
            ipfsHash: ipfsHash,
            isActive: true
        });

        emit ServiceCreated(serviceId, msg.sender, price, ipfsHash);
    }

    /// @notice Updates the price and metadata of an existing active service
    /// @param serviceId The ID of the service to update
    /// @param newPrice The new price for the service, must be > 0
    /// @param newIpfsHash The new IPFS hash of the service metadata
    function updateService(uint256 serviceId, uint256 newPrice, string memory newIpfsHash) external onlyProvider(serviceId) {
        require(newPrice > 0, "Price must be greater than zero");
        require(bytes(newIpfsHash).length > 0, "IPFS hash cannot be empty");

        Service storage s = services[serviceId];
        require(s.serviceId == serviceId, "Service does not exist");

        s.price = newPrice;
        s.ipfsHash = newIpfsHash;

        emit ServiceUpdated(serviceId, newPrice, newIpfsHash);
    }

    /// @notice Deactivates a service, only provider can deactivate
    /// @param serviceId The ID of the service to deactivate
    function deactivateService(uint256 serviceId) external onlyProvider(serviceId) {
        Service storage s = services[serviceId];
        require(s.isActive, "Already inactive");

        s.isActive = false;
        emit ServiceDeactivated(serviceId);
    }

    /// @notice Reactivates a previously deactivated service
    /// @param serviceId The ID of the service to reactivate
    function reactivateService(uint256 serviceId) external onlyProvider(serviceId) {
        Service storage s = services[serviceId];
        require(s.serviceId == serviceId, "Service does not exist");
        require(!s.isActive, "Service already active");

        s.isActive = true;
        emit ServiceReactivated(serviceId);
    }
}
