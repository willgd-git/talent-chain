// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interfaces/IPaymentManager.sol";
import "./interfaces/IServiceAgreement.sol";

/// @title Payment Manager
/// @notice Manages the escrow and distribution of funds related to service agreements.
/// @dev Integrates with ServiceAgreement for state checks and uses rulings from dispute resolutions.
contract PaymentManager is IPaymentManager {
    /// @notice Reference to the ServiceAgreement contract
    IServiceAgreement public serviceAgreement;

    /// @notice Owner address for admin functions like changing service agreement reference
    address public owner;

    /// @notice Mapping of agreementId to escrowed amount
    mapping(uint256 => uint256) public escrow;

    /// @notice Emitted when funds are deposited into the escrow for an agreement
    /// @param agreementId The ID of the agreement
    /// @param amount The amount deposited
    event FundsDeposited(uint256 indexed agreementId, uint256 amount);

    /// @notice Emitted when funds are released to the provider
    /// @param agreementId The ID of the agreement
    /// @param amount The amount released
    /// @param to The provider address receiving the funds
    event FundsReleased(uint256 indexed agreementId, uint256 amount, address indexed to);

    /// @notice Emitted when funds are refunded to the client
    /// @param agreementId The ID of the agreement
    /// @param amount The amount refunded
    /// @param to The client address receiving the refund
    event FundsRefunded(uint256 indexed agreementId, uint256 amount, address indexed to);

    /// @notice Emitted when funds are partially distributed due to a dispute ruling
    /// @param agreementId The ID of the agreement
    /// @param clientAmount The amount the client receives
    /// @param providerAmount The amount the provider receives
    event FundsDistributedAfterDispute(uint256 indexed agreementId, uint256 clientAmount, uint256 providerAmount);

    /// @notice Emitted when the ServiceAgreement address is updated
    /// @param newServiceAgreement The address of the new ServiceAgreement contract
    event ServiceAgreementAddressSet(address indexed newServiceAgreement);

    /// @notice Constructor sets the initial owner
    constructor() {
        owner = msg.sender;
    }

    /// @notice Modifier to restrict functions to the contract owner
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner");
        _;
    }

    /// @notice Modifier to restrict functions to the ServiceAgreement contract
    modifier onlyServiceAgreement() {
        require(msg.sender == address(serviceAgreement), "Only ServiceAgreement can call");
        _;
    }

    /// @notice Sets the ServiceAgreement contract address
    /// @dev Can only be called by the contract owner
    /// @param newServiceAgreement The address of the new ServiceAgreement contract
    function setServiceAgreementAddress(address newServiceAgreement) public onlyOwner {
        require(newServiceAgreement != address(0), "Invalid ServiceAgreement address");
        serviceAgreement = IServiceAgreement(newServiceAgreement);
        emit ServiceAgreementAddressSet(newServiceAgreement);
    }

    /// @notice Deposits funds into the escrow for a specific agreement.
    /// @dev Only the client of the agreement can call this function.
    ///      After depositing, it calls markAsPaid on the ServiceAgreement contract.
    /// @param agreementId The ID of the agreement.
    function depositFunds(uint256 agreementId) external payable override {
        (
            uint256 agreementIdOut,
            ,
            address client,
            ,
            uint256 amount,
            IServiceAgreement.AgreementStatus status,
            
        ) = serviceAgreement.agreements(agreementId);
        
        require(agreementIdOut == agreementId, "Agreement not found");
        require(msg.sender == client, "Only client can deposit");
        require(status == IServiceAgreement.AgreementStatus.Accepted, "Not depositable state");
        require(msg.value == amount, "Must deposit exact amount");
        require(escrow[agreementId] == 0, "Already deposited");

        escrow[agreementId] = msg.value;
        emit FundsDeposited(agreementId, msg.value);

        // Notify ServiceAgreement that funds have been deposited
        serviceAgreement.markAsPaid(agreementId);
    }

    /// @notice Releases funds to the provider after the agreement is CompletedAccepted.
    /// @dev Can only be called by the ServiceAgreement contract.
    /// @param agreementId The ID of the agreement.
    function releaseFunds(uint256 agreementId) external override onlyServiceAgreement {
        (
            uint256 agreementIdOut,
            ,
            ,
            address provider,
            ,
            IServiceAgreement.AgreementStatus status,
            
        ) = serviceAgreement.agreements(agreementId);

        require(agreementIdOut == agreementId, "Agreement not found");
        require(status == IServiceAgreement.AgreementStatus.CompletedAccepted, "Not in CompletedAccepted state");
        uint256 balance = escrow[agreementId];
        require(balance > 0, "No escrow funds");

        escrow[agreementId] = 0;
        (bool success, ) = provider.call{value: balance}("");
        require(success, "Transfer to provider failed");
        emit FundsReleased(agreementId, balance, provider);
    }

    /// @notice Distributes funds based on the final dispute ruling.
    /// @dev Can only be called by the ServiceAgreement contract.
    /// @param agreementId The ID of the agreement.
    /// @param ruling The outcome of the dispute.
    function distributeAfterDispute(uint256 agreementId, Ruling ruling) external override onlyServiceAgreement {
        (
            uint256 agreementIdOut,
            ,
            address client,
            address provider,
            ,
            IServiceAgreement.AgreementStatus status,
            
        ) = serviceAgreement.agreements(agreementId);

        require(agreementIdOut == agreementId, "Agreement not found");
        require(status == IServiceAgreement.AgreementStatus.DisputeResolved, "Not disputed");

        uint256 balance = escrow[agreementId];
        require(balance > 0, "No escrow funds");

        uint256 clientAmount;
        uint256 providerAmount;

        if (ruling == Ruling.ClientFavored) {
            clientAmount = balance;
        } else if (ruling == Ruling.ProviderFavored) {
            providerAmount = balance;
        } else if (ruling == Ruling.Split) {
            clientAmount = balance / 2;
            providerAmount = balance - clientAmount;
        } else {
            revert("Invalid ruling");
        }

        escrow[agreementId] = 0;

        if (clientAmount > 0) {
            (bool successClient, ) = client.call{value: clientAmount}("");
            require(successClient, "Client transfer failed");
        }
        if (providerAmount > 0) {
            (bool successProvider, ) = provider.call{value: providerAmount}("");
            require(successProvider, "Provider transfer failed");
        }

        emit FundsDistributedAfterDispute(agreementId, clientAmount, providerAmount);
    }
}
