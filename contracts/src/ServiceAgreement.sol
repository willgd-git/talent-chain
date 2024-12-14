// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interfaces/IServiceListing.sol";

/// @title Service Agreement Contract for TalentChain
/// @author
/// @notice Manages the lifecycle of service agreements, including negotiations, acceptance, payment, completion, and disputes.
/// @dev Integrates with ServiceListing to validate services and providers. Uses status enum for all states including paid.
contract ServiceAgreement {
    /// @notice Enumeration of possible agreement states
    /// @dev Proposed -> Accepted -> Paid -> Completed -> CompletedAccepted/Disputed
    enum AgreementStatus {
        Proposed,
        Accepted,
        Paid,
        Completed,
        CompletedAccepted,
        Disputed,
        Cancelled
    }

    /// @notice Data structure representing a service agreement
    struct Agreement {
        uint256 agreementId;
        uint256 serviceId;
        address client;
        address provider;
        uint256 amount;
        AgreementStatus status;
        uint256 completionTimestamp; // Timestamp set when provider completes
    }

    /// @notice Reference to the service listing contract for validation
    IServiceListing public serviceListing;

    /// @notice Mapping of agreementId to Agreement details
    mapping(uint256 => Agreement) public agreements;

    /// @notice Tracks the next agreement ID
    uint256 public nextAgreementId;

    /// @notice Timeout after completion during which client can accept or dispute
    uint256 public completionAcceptanceTimeout = 7 days;

    /// @notice Emitted when a new agreement is created
    event AgreementCreated(
        uint256 indexed agreementId,
        uint256 indexed serviceId,
        address indexed client,
        address provider,
        uint256 amount
    );

    /// @notice Emitted when the provider accepts the agreement
    event AgreementAcceptedByProvider(uint256 indexed agreementId);

    /// @notice Emitted when the agreement is marked as Paid
    event AgreementPaid(uint256 indexed agreementId);

    /// @notice Emitted when the provider marks the agreement as completed
    event AgreementCompleted(uint256 indexed agreementId);

    /// @notice Emitted when the client accepts the completed agreement
    event AgreementCompletedAccepted(uint256 indexed agreementId);

    /// @notice Emitted when the client disputes the completed agreement
    event AgreementDisputed(uint256 indexed agreementId);

    /// @notice Emitted when the agreement is cancelled
    event AgreementCancelled(uint256 indexed agreementId);

    /// @param serviceListingAddr The address of the ServiceListing contract
    constructor(address serviceListingAddr) {
        require(serviceListingAddr != address(0), "Invalid ServiceListing address");
        serviceListing = IServiceListing(serviceListingAddr);
    }

    /// @notice Creates a new service agreement in the Proposed state
    /// @param serviceId The ID of the referenced service
    /// @param provider The provider of the service (must match the service listing)
    /// @param amount The agreed amount, must be > 0
    /// @return agreementId The ID of the newly created agreement
    function createAgreement(uint256 serviceId, address provider, uint256 amount) external returns (uint256 agreementId) {
        require(amount > 0, "Amount must be greater than 0");
        (uint256 sId, address sProvider, , bool isActive) = serviceListing.services(serviceId);
        require(sId == serviceId, "Invalid serviceId");
        require(sProvider == provider, "Provider mismatch");
        require(isActive, "Service not active");

        agreementId = ++nextAgreementId;
        agreements[agreementId] = Agreement({
            agreementId: agreementId,
            serviceId: serviceId,
            client: msg.sender,
            provider: provider,
            amount: amount,
            status: AgreementStatus.Proposed,
            completionTimestamp: 0
        });

        emit AgreementCreated(agreementId, serviceId, msg.sender, provider, amount);
    }

    /// @notice Updates the agreement amount during Proposed stage, allowing renegotiation before acceptance
    /// @dev Either the client or the provider can call this if status == Proposed
    /// @param agreementId The ID of the agreement
    /// @param newAmount The new amount, must be > 0
    function updateAgreementAmount(uint256 agreementId, uint256 newAmount) external {
        require(newAmount > 0, "Amount must be greater than 0");
        Agreement storage a = agreements[agreementId];
        require(a.agreementId == agreementId, "Agreement not found");
        require(a.status == AgreementStatus.Proposed, "Can only edit in Proposed state");
        require(msg.sender == a.client || msg.sender == a.provider, "Not a participant");

        a.amount = newAmount;
        // We could emit an event if desired, e.g. AgreementUpdated(agreementId, newAmount)
    }

    /// @notice Provider accepts the proposed agreement, moving it to Accepted state
    /// @param agreementId The ID of the agreement
    function acceptAgreement(uint256 agreementId) external {
        Agreement storage a = agreements[agreementId];
        require(a.agreementId == agreementId, "Agreement not found");
        require(a.provider == msg.sender, "Only provider can accept");
        require(a.status == AgreementStatus.Proposed, "Wrong status");

        a.status = AgreementStatus.Accepted;
        emit AgreementAcceptedByProvider(agreementId);
    }

    /// @notice Marks the agreement as Paid
    /// @dev In a real scenario, PaymentManager would call this function after funds are deposited
    /// @param agreementId The ID of the agreement
    function markAsPaid(uint256 agreementId) external {
        Agreement storage a = agreements[agreementId];
        require(a.agreementId == agreementId, "Agreement not found");
        require(a.status == AgreementStatus.Accepted, "Must be Accepted before Paid");
        // In real scenario, ensure caller is PaymentManager or check auth

        a.status = AgreementStatus.Paid;
        emit AgreementPaid(agreementId);
    }

    /// @notice Provider completes the service
    /// @dev Must be Paid before Completed
    /// @param agreementId The ID of the agreement
    function completeAgreement(uint256 agreementId) external {
        Agreement storage a = agreements[agreementId];
        require(a.agreementId == agreementId, "Agreement not found");
        require(a.provider == msg.sender, "Only provider can complete");
        require(a.status == AgreementStatus.Paid, "Must be Paid before Completed");

        a.status = AgreementStatus.Completed;
        a.completionTimestamp = block.timestamp;
        emit AgreementCompleted(agreementId);
    }

    /// @notice Client accepts the completed agreement
    /// @dev Must be Completed before accepted
    /// @param agreementId The ID of the agreement
    function acceptCompletedAgreement(uint256 agreementId) external {
        Agreement storage a = agreements[agreementId];
        require(a.agreementId == agreementId, "Agreement not found");
        require(a.client == msg.sender, "Only client can accept");
        require(a.status == AgreementStatus.Completed, "Must be Completed before accepted");

        a.status = AgreementStatus.CompletedAccepted;
        emit AgreementCompletedAccepted(agreementId);
    }

    /// @notice Client disputes the completed agreement
    /// @dev Must be Completed before Disputed
    /// @param agreementId The ID of the agreement
    function disputeCompletedAgreement(uint256 agreementId) external {
        Agreement storage a = agreements[agreementId];
        require(a.agreementId == agreementId, "Agreement not found");
        require(a.client == msg.sender, "Only client can dispute");
        require(a.status == AgreementStatus.Completed, "Must be Completed before dispute");

        a.status = AgreementStatus.Disputed;
        emit AgreementDisputed(agreementId);
    }

    /// @notice Cancel the agreement if status < Paid
    /// @dev Proposed or Accepted can be cancelled by either participant
    /// @param agreementId The ID of the agreement
    function cancelAgreement(uint256 agreementId) external {
        Agreement storage a = agreements[agreementId];
        require(a.agreementId == agreementId, "Agreement not found");
        require(a.client == msg.sender || a.provider == msg.sender, "Not participant");
        // States below Paid: Proposed(0), Accepted(1)
        require(a.status == AgreementStatus.Proposed || a.status == AgreementStatus.Accepted, "Cannot cancel now");

        a.status = AgreementStatus.Cancelled;
        emit AgreementCancelled(agreementId);
    }

    /// @notice If client silent after completion for completionAcceptanceTimeout, auto-accept
    /// @param agreementId The ID of the agreement
    function finalizeCompletionIfTimeout(uint256 agreementId) external {
        Agreement storage a = agreements[agreementId];
        require(a.agreementId == agreementId, "Agreement not found");
        require(a.status == AgreementStatus.Completed, "Must be Completed");
        require(block.timestamp > a.completionTimestamp + completionAcceptanceTimeout, "Timeout not reached");

        a.status = AgreementStatus.CompletedAccepted;
        emit AgreementCompletedAccepted(agreementId);
    }
}
