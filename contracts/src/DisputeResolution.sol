// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interfaces/IServiceAgreement.sol";
import "./interfaces/IPaymentManager.sol";

/// @title DisputeResolution
/// @notice Manages the process of raising and resolving disputes for agreements.
/// @dev Integrates with ServiceAgreement and relies on an owner to set up addresses and an arbitrator to finalize disputes.
contract DisputeResolution {
    /// @notice The owner of the DisputeResolution contract
    address public owner;

    /// @notice The arbitrator address who can finalize disputes
    address public arbitrator;

    /// @notice Reference to the ServiceAgreement contract
    IServiceAgreement public serviceAgreement;

    /// @notice Emitted when the ServiceAgreement address is updated
    /// @param newServiceAgreement The address of the new ServiceAgreement contract
    event ServiceAgreementAddressSet(address indexed newServiceAgreement);

    /// @notice Emitted when the arbitrator address is updated
    /// @param newArbitrator The address of the new arbitrator
    event ArbitratorSet(address indexed newArbitrator);

    /// @notice Constructor sets the initial owner
    constructor() {
        owner = msg.sender;
    }

    /// @notice Modifier to restrict functions to the contract owner
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner");
        _;
    }

    /// @notice Modifier to restrict functions to the arbitrator
    modifier onlyArbitrator() {
        require(msg.sender == arbitrator, "Only arbitrator");
        _;
    }

    /// @notice Sets the ServiceAgreement contract address
    /// @dev Can only be called by the contract owner
    /// @param newServiceAgreement The address of the new ServiceAgreement contract
    function setServiceAgreementAddress(address newServiceAgreement) external onlyOwner {
        require(newServiceAgreement != address(0), "Invalid ServiceAgreement address");
        serviceAgreement = IServiceAgreement(newServiceAgreement);
        emit ServiceAgreementAddressSet(newServiceAgreement);
    }

    /// @notice Sets the arbitrator address
    /// @dev Can only be called by the contract owner
    /// @param newArbitrator The address of the arbitrator
    function setArbitrator(address newArbitrator) external onlyOwner {
        require(newArbitrator != address(0), "Invalid arbitrator address");
        arbitrator = newArbitrator;
        emit ArbitratorSet(newArbitrator);
    }

    /// @notice Raises a dispute for a given agreement.
    /// @dev Can only be called by the client or provider of the agreement if the agreement is in Completed state.
    /// @param agreementId The ID of the agreement
    function raiseDispute(uint256 agreementId) external {
        (
            uint256 agreementIdOut,
            ,
            address client,
            address provider,
            ,
            IServiceAgreement.AgreementStatus status,
            
        ) = serviceAgreement.agreements(agreementId);

        require(agreementIdOut == agreementId, "Agreement not found");
        require(msg.sender == client || msg.sender == provider, "Caller not participant");
        require(status == IServiceAgreement.AgreementStatus.Completed, "Must be Completed to dispute");

        // Call ServiceAgreement to move to Disputed state
        serviceAgreement.disputeCompletedAgreement(agreementId);
    }

    /// @notice Resolves the dispute by providing a ruling and calling `resolveDispute` on the ServiceAgreement.
    /// @dev Can only be called by the arbitrator.
    /// @param agreementId The ID of the disputed agreement
    /// @param ruling The outcome of the dispute (ClientFavored, ProviderFavored, or Split)
    function resolveDispute(uint256 agreementId, IPaymentManager.Ruling ruling) external onlyArbitrator {
        // Call ServiceAgreement to finalize dispute (Disputed -> DisputeResolved)
        serviceAgreement.resolveDispute(agreementId, ruling);
    }
}
