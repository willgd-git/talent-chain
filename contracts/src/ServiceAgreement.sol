// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interfaces/IServiceListing.sol";
import "./interfaces/IPaymentManager.sol";
import "./interfaces/IServiceAgreement.sol";

/// @title Service Agreement Contract for TalentChain
/// @notice Manages the lifecycle of service agreements, including negotiations, acceptance, payment, completion, and disputes.
/// @dev Integrates with ServiceListing to validate services and providers, and PaymentManager to handle fund releases.
contract ServiceAgreement is IServiceAgreement {
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

    /// @notice Reference to the ServiceListing contract
    IServiceListing public serviceListing;

    /// @notice Reference to the PaymentManager contract
    IPaymentManager public paymentManager;

    /// @notice Reference to the DisputeResolution contract
    address public disputeResolution;

    /// @notice Owner address for administrative functions
    address public owner;

    /// @notice Mapping of agreementId to Agreement details
    mapping(uint256 => Agreement) public agreements;

    /// @notice Tracks the next agreement ID to assign
    uint256 public nextAgreementId;

    /// @notice Timeout after completion during which client can accept or dispute
    uint256 public completionAcceptanceTimeout = 7 days;

    /// @notice Emitted when a new agreement is created
    /// @param agreementId The ID of the created agreement
    /// @param serviceId The ID of the referenced service
    /// @param client The address of the client
    /// @param provider The address of the provider
    /// @param amount The agreed amount for the service
    event AgreementCreated(
        uint256 indexed agreementId,
        uint256 indexed serviceId,
        address indexed client,
        address provider,
        uint256 amount
    );

    /// @notice Emitted when the provider accepts the agreement
    /// @param agreementId The ID of the accepted agreement
    event AgreementAcceptedByProvider(uint256 indexed agreementId);

    /// @notice Emitted when the agreement is marked as Paid
    /// @param agreementId The ID of the paid agreement
    event AgreementPaid(uint256 indexed agreementId);

    /// @notice Emitted when the provider completes the agreement
    /// @param agreementId The ID of the completed agreement
    event AgreementCompleted(uint256 indexed agreementId);

    /// @notice Emitted when the client accepts the completed agreement
    /// @param agreementId The ID of the agreement
    event AgreementCompletedAccepted(uint256 indexed agreementId);

    /// @notice Emitted when the client disputes the completed agreement
    /// @param agreementId The ID of the agreement
    event AgreementDisputed(uint256 indexed agreementId);

    /// @notice Emitted when the agreement is cancelled
    /// @param agreementId The ID of the cancelled agreement
    event AgreementCancelled(uint256 indexed agreementId);

    /// @notice Emitted when the PaymentManager address is updated
    /// @param newPaymentManager The address of the new PaymentManager contract
    event PaymentManagerAddressSet(address indexed newPaymentManager);

    /// @notice Emitted when the ServiceListing address is updated
    /// @param newServiceListing The address of the new ServiceListing contract
    event ServiceListingAddressSet(address indexed newServiceListing);

    /// @notice Emitted when the agreement amount is updated
    /// @param agreementId The ID of the agreement
    /// @param oldAmount The previous amount
    /// @param newAmount The updated amount
    event AgreementAmountUpdated(uint256 indexed agreementId, uint256 oldAmount, uint256 newAmount);

    /// @notice Emitted when the dispute is resolved and funds distribution occurs
    event AgreementDisputeResolved(uint256 indexed agreementId, IPaymentManager.Ruling ruling);

    /// @notice Modifier to restrict functions to the contract owner
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner");
        _;
    }

    /// @notice Modifier to ensure only the DisputeResolution contract can resolve disputes
    modifier onlyDisputeResolution() {
        require(msg.sender == disputeResolution, "Only DisputeResolution can call");
        _;
    }

    /// @notice Constructor sets the owner
    constructor() {
        owner = msg.sender;
    }

    /// @notice Sets the ServiceListing contract address
    /// @dev Can only be called by the contract owner
    /// @param serviceListingAddr The address of the ServiceListing contract
    function setServiceListingAddress(address serviceListingAddr) external onlyOwner {
        require(serviceListingAddr != address(0), "Invalid ServiceListing address");
        serviceListing = IServiceListing(serviceListingAddr);
        emit ServiceListingAddressSet(serviceListingAddr);
    }

    /// @notice Sets the PaymentManager contract address
    /// @dev Can only be called by the contract owner
    /// @param paymentManagerAddr The address of the PaymentManager contract
    function setPaymentManagerAddress(address paymentManagerAddr) external onlyOwner {
        require(paymentManagerAddr != address(0), "Invalid PaymentManager address");
        paymentManager = IPaymentManager(paymentManagerAddr);
        emit PaymentManagerAddressSet(paymentManagerAddr);
    }

    /// @notice Sets the DisputeResolution contract address
    /// @dev Can only be called by the contract owner
    /// @param disputeResolutionAddr The address of the DisputeResolution contract
    function setDisputeResolutionAddress(address disputeResolutionAddr) external onlyOwner {
        require(disputeResolutionAddr != address(0), "Invalid DisputeResolution address");
        disputeResolution = disputeResolutionAddr;
    }

    /// @notice Creates a new service agreement in the Proposed state
    /// @dev Requires ServiceListing to be set and validate service details
    /// @param serviceId The ID of the referenced service
    /// @param provider The provider of the service (must match the service listing)
    /// @param amount The agreed amount, must be > 0
    /// @return agreementId The ID of the newly created agreement
    function createAgreement(uint256 serviceId, address provider, uint256 amount) external returns (uint256 agreementId) {
        require(amount > 0, "Amount must be greater than 0");
        (
            uint256 sId,
            address sProvider,
            ,
            bool isActive
        ) = serviceListing.services(serviceId);
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

        uint256 oldAmount = a.amount;
        a.amount = newAmount;
        emit AgreementAmountUpdated(agreementId, oldAmount, newAmount);
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
    /// @dev Called by PaymentManager
    /// @param agreementId The ID of the agreement
    function markAsPaid(uint256 agreementId) external {
        require(msg.sender == address(paymentManager), "Only PaymentManager can mark as paid");

        Agreement storage a = agreements[agreementId];
        require(a.agreementId == agreementId, "Agreement not found");
        require(a.status == AgreementStatus.Accepted, "Must be Accepted before Paid");

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

    /// @notice Client accepts the completed agreement and triggers fund release
    /// @dev Must be Completed before accepted
    /// @param agreementId The ID of the agreement
    function acceptCompletedAgreement(uint256 agreementId) external {
        Agreement storage a = agreements[agreementId];
        require(a.agreementId == agreementId, "Agreement not found");
        require(a.client == msg.sender, "Only client can accept");
        require(a.status == AgreementStatus.Completed, "Must be Completed before accepted");

        a.status = AgreementStatus.CompletedAccepted;

        // Release funds via PaymentManager
        paymentManager.releaseFunds(agreementId);

        emit AgreementCompletedAccepted(agreementId);
    }

    /// @notice Client disputes the completed agreement
    /// @dev Must be Completed before Disputed
    /// @param agreementId The ID of the agreement
    function disputeCompletedAgreement(uint256 agreementId) external onlyDisputeResolution {
        Agreement storage a = agreements[agreementId];
        require(a.agreementId == agreementId, "Agreement not found");
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
        require(a.client == msg.sender || a.provider == msg.sender, "Not a participant");
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
        
        // Release funds via PaymentManager
        paymentManager.releaseFunds(agreementId);

        emit AgreementCompletedAccepted(agreementId);
    }

    /// @notice Resolve the dispute by distributing funds according to the ruling and updating the agreement status
    /// @dev Must be Disputed before Resolved
    ///      Can only be called by the DisputeResolution contract
    /// @param agreementId The ID of the agreement
    /// @param ruling The outcome of the dispute (ClientFavored, ProviderFavored, or Split)
    function resolveDispute(uint256 agreementId, IPaymentManager.Ruling ruling) external onlyDisputeResolution {
        Agreement storage a = agreements[agreementId];
        require(a.agreementId == agreementId, "Agreement not found");
        require(a.status == AgreementStatus.Disputed, "Must be Disputed before resolving");

        // Update the status to DisputeResolved
        a.status = AgreementStatus.DisputeResolved;

        // Distribute funds via PaymentManager according to the ruling
        paymentManager.distributeAfterDispute(agreementId, ruling);
        
        emit AgreementDisputeResolved(agreementId, ruling);
    }
}
