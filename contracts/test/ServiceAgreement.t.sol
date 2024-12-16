// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {UserRegistry} from "../src/UserRegistry.sol";
import {ServiceListing} from "../src/ServiceListing.sol";
import {ServiceAgreement} from "../src/ServiceAgreement.sol";
import {PaymentManager} from "../src/PaymentManager.sol";
import {IServiceAgreement} from "../src/interfaces/IServiceAgreement.sol";
import {IPaymentManager} from "../src/interfaces/IPaymentManager.sol";
import {IUserRegistry} from "../src/interfaces/IUserRegistry.sol";
import {IServiceListing} from "../src/interfaces/IServiceListing.sol";

/// @title ServiceAgreementBaseTest
/// @notice Base test contract for ServiceAgreement. Sets up UserRegistry, ServiceListing, PaymentManager, and ServiceAgreement.
/// @dev Provides helper methods for repetitive tasks and configures the environment before each test.
abstract contract ServiceAgreementBaseTest is Test {
    // Events from ServiceAgreement
    event AgreementCreated(
        uint256 indexed agreementId,
        uint256 indexed serviceId,
        address indexed client,
        address provider,
        uint256 amount
    );
    event AgreementAcceptedByProvider(uint256 indexed agreementId);
    event AgreementPaid(uint256 indexed agreementId);
    event AgreementCompleted(uint256 indexed agreementId);
    event AgreementCompletedAccepted(uint256 indexed agreementId);
    event AgreementDisputed(uint256 indexed agreementId);
    event AgreementCancelled(uint256 indexed agreementId);
    event PaymentManagerAddressSet(address indexed newPaymentManager);
    event ServiceListingAddressSet(address indexed newServiceListing);
    event AgreementAmountUpdated(uint256 indexed agreementId, uint256 oldAmount, uint256 newAmount);
    event AgreementDisputeResolved(uint256 indexed agreementId, IPaymentManager.Ruling ruling);


    // Events from PaymentManager
    event FundsDeposited(uint256 indexed agreementId, uint256 amount);
    event FundsReleased(uint256 indexed agreementId, uint256 amount, address indexed to);
    event FundsRefunded(uint256 indexed agreementId, uint256 amount, address indexed to);
    event FundsDistributedAfterDispute(uint256 indexed agreementId, uint256 clientAmount, uint256 providerAmount);

    UserRegistry public userRegistry;
    ServiceListing public serviceListing;
    ServiceAgreement public serviceAgreement;
    PaymentManager public paymentManager;

    address owner = address(1);
    address provider1 = address(2);
    address client1 = address(3);
    address nonParticipant = address(4);
    address disputeResolution = address(5);

    uint256 serviceId;
    uint256 agreementId;

    /// @notice Setup runs before each test method
    function setUp() public virtual {
        // Deploy UserRegistry
        vm.startPrank(owner);
        userRegistry = new UserRegistry();
        vm.stopPrank();

        // Deploy ServiceListing and set UserRegistry
        vm.startPrank(owner);
        serviceListing = new ServiceListing();
        serviceListing.setUserRegistry(address(userRegistry));
        vm.stopPrank();

        // Register provider
        vm.prank(provider1);
        userRegistry.registerUser("userProfileHash");

        // Deploy PaymentManager (no ServiceAgreement set yet)
        vm.startPrank(owner);
        paymentManager = new PaymentManager();
        vm.stopPrank();

        // Deploy ServiceAgreement (no ServiceListing or PaymentManager set yet)
        vm.startPrank(owner);
        serviceAgreement = new ServiceAgreement();
        serviceAgreement.setServiceListingAddress(address(serviceListing));
        serviceAgreement.setPaymentManagerAddress(address(paymentManager));
        vm.stopPrank();

        // Set ServiceAgreement address in PaymentManager
        vm.startPrank(owner);
        paymentManager.setServiceAgreementAddress(address(serviceAgreement));
        vm.stopPrank();

        // Create a service in ServiceListing
        vm.prank(provider1);
        serviceId = serviceListing.createService(100, "ipfsHashes");
    }

    /// @notice Helper function: create an agreement
    function createAgreementHelper(address client, uint256 _serviceId, address _provider, uint256 _amount) internal returns (uint256) {
        vm.prank(client);
        return serviceAgreement.createAgreement(_serviceId, _provider, _amount);
    }

    /// @notice Helper function: accept an agreement by the provider
    function acceptAgreementHelper(address provider, uint256 _agreementId) internal {
        vm.prank(provider);
        serviceAgreement.acceptAgreement(_agreementId);
    }

    /// @notice Helper function: simulate marking agreement as paid
    /// @dev In real scenario, PaymentManager.depositFunds would be called by ServiceAgreement
    function depositFundsHelper(uint256 _agreementId) internal {
        // Simulate depositing funds via PaymentManager
        // Client1 sends the exact amount to PaymentManager
        vm.deal(client1, 100 ether);
        vm.startPrank(client1);
        paymentManager.depositFunds{value:100}(_agreementId);
        vm.stopPrank();
    }

    /// @notice Helper function: complete an agreement by the provider
    function completeAgreementHelper(address provider, uint256 _agreementId) internal {
        vm.prank(provider);
        serviceAgreement.completeAgreement(_agreementId);
    }

    /// @notice Warp time forward
    function warpForward(uint256 secondsToWarp) internal {
        vm.warp(block.timestamp + secondsToWarp);
    }
}

/// @title ServiceAgreementCreateTest
/// @notice Tests creating agreements in ServiceAgreement
contract ServiceAgreementCreateTest is ServiceAgreementBaseTest {

    function test_CreateAgreement_Success() public {
        vm.prank(client1);
        vm.expectEmit(true, true, false, true);
        emit AgreementCreated(1, serviceId, client1, provider1, 100);
        uint256 newAgreementId = serviceAgreement.createAgreement(serviceId, provider1, 100);

        (
            uint256 aId,
            uint256 sId,
            address client,
            address prov,
            uint256 amount,
            IServiceAgreement.AgreementStatus status,
            uint256 completionTimestamp
        ) = serviceAgreement.agreements(newAgreementId);

        assertEq(aId, 1, "Agreement ID should be 1");
        assertEq(sId, serviceId, "Service ID should match");
        assertEq(client, client1, "Client should match");
        assertEq(prov, provider1, "Provider should match");
        assertEq(amount, 100, "Amount should match");
        assertEq(uint8(status), uint8(IServiceAgreement.AgreementStatus.Proposed), "Status should be Proposed");
        assertEq(completionTimestamp, 0, "completionTimestamp should be 0");
    }

    function test_CreateAgreement_RevertIf_AmountZero() public {
        vm.prank(client1);
        vm.expectRevert("Amount must be greater than 0");
        serviceAgreement.createAgreement(serviceId, provider1, 0);
    }

    function test_CreateAgreement_RevertIf_InvalidService() public {
        vm.prank(client1);
        vm.expectRevert("Invalid serviceId");
        serviceAgreement.createAgreement(999, provider1, 100);
    }

    function test_CreateAgreement_RevertIf_ProviderMismatch() public {
        // Create another service with a different provider
        address provider2 = address(6);
        vm.prank(provider2);
        userRegistry.registerUser("userProfileHash");
        vm.prank(provider2);
        uint256 newServiceId = serviceListing.createService(200, "ipfsHashes");

        vm.prank(client1);
        vm.expectRevert("Provider mismatch");
        serviceAgreement.createAgreement(newServiceId, provider1, 100);
    }
}

/// @title ServiceAgreementUpdateTest
/// @notice Tests updating the agreement amount in ServiceAgreement
contract ServiceAgreementUpdateTest is ServiceAgreementBaseTest {

    function setUp() public override {
        super.setUp();
        agreementId = createAgreementHelper(client1, serviceId, provider1, 100);
    }

    function test_UpdateAgreementAmount_Success() public {
        vm.prank(client1);
        vm.expectEmit(true, false, false, true);
        emit AgreementAmountUpdated(agreementId, 100, 150);
        serviceAgreement.updateAgreementAmount(agreementId, 150);

        (,,,,uint256 amount,IServiceAgreement.AgreementStatus status,) = serviceAgreement.agreements(agreementId);
        assertEq(amount, 150, "Amount should be updated");
        assertEq(uint8(status), uint8(IServiceAgreement.AgreementStatus.Proposed), "Status still Proposed");
    }

    function test_UpdateAgreementAmount_Success_ByProvider() public {
        vm.prank(provider1);
        vm.expectEmit(true, false, false, true);
        emit AgreementAmountUpdated(agreementId, 100, 200);
        serviceAgreement.updateAgreementAmount(agreementId, 200);

        (,,,,uint256 amount,,) = serviceAgreement.agreements(agreementId);
        assertEq(amount, 200, "Amount should be updated");
    }

    function test_UpdateAgreementAmount_RevertIf_AmountZero() public {
        vm.prank(provider1);
        vm.expectRevert("Amount must be greater than 0");
        serviceAgreement.updateAgreementAmount(agreementId, 0);
    }

    function test_UpdateAgreementAmount_RevertIf_NotParticipant() public {
        vm.prank(nonParticipant);
        vm.expectRevert("Not a participant");
        serviceAgreement.updateAgreementAmount(agreementId, 150);
    }

    function test_UpdateAgreementAmount_RevertIf_NotProposed() public {
        acceptAgreementHelper(provider1, agreementId);
        vm.prank(client1);
        vm.expectRevert("Can only edit in Proposed state");
        serviceAgreement.updateAgreementAmount(agreementId, 150);
    }
}

/// @title ServiceAgreementAcceptTest
/// @notice Tests accepting agreements by providers
contract ServiceAgreementAcceptTest is ServiceAgreementBaseTest {

    function setUp() public override {
        super.setUp();
        agreementId = createAgreementHelper(client1, serviceId, provider1, 100);
    }

    function test_AcceptAgreement_Success() public {
        vm.prank(provider1);
        vm.expectEmit(true, false, false, true);
        emit AgreementAcceptedByProvider(agreementId);
        serviceAgreement.acceptAgreement(agreementId);

        (,,,,,IServiceAgreement.AgreementStatus status,) = serviceAgreement.agreements(agreementId);
        assertEq(uint8(status), uint8(IServiceAgreement.AgreementStatus.Accepted), "Status should be Accepted");
    }

    function test_AcceptAgreement_RevertIf_NotProvider() public {
        vm.prank(client1);
        vm.expectRevert("Only provider can accept");
        serviceAgreement.acceptAgreement(agreementId);
    }

    function test_AcceptAgreement_RevertIf_WrongStatus() public {
        vm.prank(client1);
        serviceAgreement.cancelAgreement(agreementId);

        vm.prank(provider1);
        vm.expectRevert("Wrong status");
        serviceAgreement.acceptAgreement(agreementId);
    }
}

/// @title ServiceAgreementPaymentAndCompletionTest
/// @notice Tests marking agreements as paid and completing them
contract ServiceAgreementPaymentAndCompletionTest is ServiceAgreementBaseTest {

    function setUp() public override {
        super.setUp();
        agreementId = createAgreementHelper(client1, serviceId, provider1, 100);
        acceptAgreementHelper(provider1, agreementId);
        depositFundsHelper(agreementId);
    }

    function test_MarkAsPaid_Success() public view {
        (,,,,,IServiceAgreement.AgreementStatus status,) = serviceAgreement.agreements(agreementId);
        assertEq(uint8(status), uint8(IServiceAgreement.AgreementStatus.Paid), "Status should be Paid");
    }

    function test_MarkAsPaid_RevertIf_NotPaymentManager() public {
        vm.prank(nonParticipant);
        vm.expectRevert("Only PaymentManager can mark as paid");
        serviceAgreement.markAsPaid(agreementId);
    }

    function test_CompleteAgreement_Success() public {
        vm.prank(provider1);
        vm.expectEmit(true, false, false, true);
        emit AgreementCompleted(agreementId);
        serviceAgreement.completeAgreement(agreementId);

        (,,,,,IServiceAgreement.AgreementStatus status,) = serviceAgreement.agreements(agreementId);
        assertEq(uint8(status), uint8(IServiceAgreement.AgreementStatus.Completed), "Status should be Completed");
    }

    function test_CompleteAgreement_RevertIf_NotProvider() public {
        vm.prank(client1);
        vm.expectRevert("Only provider can complete");
        serviceAgreement.completeAgreement(agreementId);
    }

    function test_CompleteAgreement_RevertIf_NotPaid() public {
        uint256 newAg = createAgreementHelper(client1, serviceId, provider1, 100);
        acceptAgreementHelper(provider1, newAg);
        // Not marked as paid yet
        vm.prank(provider1);
        vm.expectRevert("Must be Paid before Completed");
        serviceAgreement.completeAgreement(newAg);
    }
}

/// @title ServiceAgreementFinalizationTest
/// @notice Tests accepting completed agreements and finalizing after timeout
contract ServiceAgreementFinalizationTest is ServiceAgreementBaseTest {

    function setUp() public override {
        super.setUp();
        agreementId = createAgreementHelper(client1, serviceId, provider1, 100);
        acceptAgreementHelper(provider1, agreementId);
        depositFundsHelper(agreementId);
        completeAgreementHelper(provider1, agreementId);
    }

    function test_AcceptCompletedAgreement_Success() public {
        vm.prank(client1);
        vm.expectEmit(true, false, false, true);
        emit FundsReleased(agreementId, 100, provider1);
        vm.expectEmit(true, false, false, true);
        emit AgreementCompletedAccepted(agreementId);
        serviceAgreement.acceptCompletedAgreement(agreementId);

        (,,,,,IServiceAgreement.AgreementStatus status,) = serviceAgreement.agreements(agreementId);
        assertEq(uint8(status), uint8(IServiceAgreement.AgreementStatus.CompletedAccepted), "Status should be CompletedAccepted");

        uint256 escrowBalance = paymentManager.escrow(agreementId);
        assertEq(escrowBalance, 0, "Escrow should be empty after release");
    }

    function test_AcceptCompletedAgreement_RevertIf_NotClient() public {
        vm.prank(provider1);
        vm.expectRevert("Only client can accept");
        serviceAgreement.acceptCompletedAgreement(agreementId);
    }

    function test_AcceptCompletedAgreement_RevertIf_NotCompleted() public {
        uint256 newAg = createAgreementHelper(client1, serviceId, provider1, 100);
        acceptAgreementHelper(provider1, newAg);
        depositFundsHelper(newAg);
        // Not completed yet
        vm.prank(client1);
        vm.expectRevert("Must be Completed before accepted");
        serviceAgreement.acceptCompletedAgreement(newAg);
    }

    function test_FinalizeCompletionIfTimeout_Success() public {
        // Warp time forward beyond timeout
        warpForward(serviceAgreement.completionAcceptanceTimeout() + 1);

        vm.prank(client1);
        vm.expectEmit(true, false, false, true);
        emit FundsReleased(agreementId, 100, provider1);
        vm.expectEmit(true, false, false, true);
        emit AgreementCompletedAccepted(agreementId);
        serviceAgreement.finalizeCompletionIfTimeout(agreementId);

        (,,,,,IServiceAgreement.AgreementStatus status,) = serviceAgreement.agreements(agreementId);
        assertEq(uint8(status), uint8(IServiceAgreement.AgreementStatus.CompletedAccepted), "Status should be CompletedAccepted");

        uint256 escrowBalance = paymentManager.escrow(agreementId);
        assertEq(escrowBalance, 0, "Escrow should be empty after release");
    }

    function test_FinalizeCompletionIfTimeout_RevertIf_NotCompleted() public {
        uint256 newAg = createAgreementHelper(client1, serviceId, provider1, 100);
        acceptAgreementHelper(provider1, newAg);
        depositFundsHelper(newAg);
        // Not completed yet
        vm.prank(client1);
        vm.expectRevert("Must be Completed");
        serviceAgreement.finalizeCompletionIfTimeout(newAg);
    }

    function test_FinalizeCompletionIfTimeout_RevertIf_NotTimeoutYet() public {
        vm.prank(client1);
        vm.expectRevert("Timeout not reached");
        serviceAgreement.finalizeCompletionIfTimeout(agreementId);
    }
}

/// @title ServiceAgreementSetServiceListingTest
/// @notice Tests setting the ServiceListing address in ServiceAgreement
contract ServiceAgreementSetServiceListingTest is ServiceAgreementBaseTest {
    ServiceListing public newServiceListing;

    function test_SetServiceListingAddress_Success() public {
        // Deploy a new ServiceListing
        vm.startPrank(owner);
        newServiceListing = new ServiceListing();
        newServiceListing.setUserRegistry(address(userRegistry));
        vm.expectEmit(true, false, false, false);
        emit ServiceListingAddressSet(address(newServiceListing));
        serviceAgreement.setServiceListingAddress(address(newServiceListing));
        vm.stopPrank();

        assertEq(address(serviceAgreement.serviceListing()), address(newServiceListing), "ServiceListing should be updated");
    }

    function test_SetServiceListingAddress_RevertIf_NotOwner() public {
        // Deploy a new ServiceListing
        vm.prank(owner);
        newServiceListing = new ServiceListing();
        vm.prank(owner);
        newServiceListing.setUserRegistry(address(userRegistry));

        vm.prank(nonParticipant);
        vm.expectRevert("Only owner");
        serviceAgreement.setServiceListingAddress(address(newServiceListing));
    }

    function test_SetServiceListingAddress_RevertIf_InvalidAddress() public {
        vm.prank(owner);
        vm.expectRevert("Invalid ServiceListing address");
        serviceAgreement.setServiceListingAddress(address(0));
    }
}

/// @title ServiceAgreementSetPaymentManagerTest
/// @notice Tests setting the PaymentManager address in ServiceAgreement
contract ServiceAgreementSetPaymentManagerTest is ServiceAgreementBaseTest {
    PaymentManager public newPaymentManager;

    function test_SetPaymentManagerAddress_Success() public {
        vm.startPrank(owner);
        newPaymentManager = new PaymentManager();
        vm.expectEmit(true, false, false, false);
        emit PaymentManagerAddressSet(address(newPaymentManager));
        serviceAgreement.setPaymentManagerAddress(address(newPaymentManager));

        assertEq(address(serviceAgreement.paymentManager()), address(newPaymentManager), "PaymentManager should be updated");
    }

    function test_SetPaymentManagerAddress_RevertIf_NotOwner() public {
        vm.prank(owner);
        newPaymentManager = new PaymentManager();

        vm.prank(nonParticipant);
        vm.expectRevert("Only owner");
        serviceAgreement.setPaymentManagerAddress(address(newPaymentManager));
    }

    function test_SetPaymentManagerAddress_RevertIf_InvalidAddress() public {
        vm.prank(owner);
        vm.expectRevert("Invalid PaymentManager address");
        serviceAgreement.setPaymentManagerAddress(address(0));
    }
}

/// @title ServiceAgreementDisputeCompletedTest
/// @notice Tests the disputeCompletedAgreement function of ServiceAgreement
contract ServiceAgreementDisputeCompletedTest is ServiceAgreementBaseTest {

    function setUp() public override {
        super.setUp();
        // Set the dispute resolution address in ServiceAgreement
        // Assume ServiceAgreement has a function setDisputeResolutionAddress
        vm.prank(owner);
        serviceAgreement.setDisputeResolutionAddress(disputeResolution);

        // Create and accept agreement
        agreementId = createAgreementHelper(client1, serviceId, provider1, 100);
        acceptAgreementHelper(provider1, agreementId);
    }

    /// @notice Tests revert if caller not DisputeResolution
    function test_DisputeCompleted_RevertIf_NotDisputeResolution() public {
        // Make agreement Completed
        depositFundsHelper(agreementId); // Paid
        completeAgreementHelper(provider1, agreementId); // Completed

        vm.prank(nonParticipant);
        vm.expectRevert("Only DisputeResolution can call"); // Assuming the modifier revert message
        serviceAgreement.disputeCompletedAgreement(agreementId);
    }

    /// @notice Tests revert if agreement not Completed state
    function test_DisputeCompleted_RevertIf_NotCompleted() public {
        // Currently agreement is Accepted, not Completed yet
        vm.prank(disputeResolution);
        vm.expectRevert("Must be Completed before dispute");
        serviceAgreement.disputeCompletedAgreement(agreementId);
    }

    /// @notice Tests successful dispute if called by DisputeResolution on a Completed agreement
    function test_DisputeCompleted_Success() public {
        // Move to Completed
        depositFundsHelper(agreementId); // Paid
        completeAgreementHelper(provider1, agreementId); // Completed now

        vm.prank(disputeResolution);
        vm.expectEmit(true, false, false, true);
        emit AgreementDisputed(agreementId);
        serviceAgreement.disputeCompletedAgreement(agreementId);

        (,,,,,IServiceAgreement.AgreementStatus status,) = serviceAgreement.agreements(agreementId);
        assertEq(uint8(status), uint8(IServiceAgreement.AgreementStatus.Disputed), "Should be Disputed after call");
    }
}

/// @title ServiceAgreementResolveDisputeTest
/// @notice Tests resolving a dispute in ServiceAgreement
contract ServiceAgreementResolveDisputeTest is ServiceAgreementBaseTest {

    function setUp() public override {
        super.setUp();
        // Set the DisputeResolution address
        vm.prank(owner);
        serviceAgreement.setDisputeResolutionAddress(disputeResolution);

        // Create an agreement and move it to Disputed state
        agreementId = createAgreementHelper(client1, serviceId, provider1, 100);
        acceptAgreementHelper(provider1, agreementId);
        depositFundsHelper(agreementId);
        completeAgreementHelper(provider1, agreementId);

        // Client disputes the agreement
        vm.prank(disputeResolution);
        serviceAgreement.disputeCompletedAgreement(agreementId);

        // Ensure it is Disputed now
        (,,,,,IServiceAgreement.AgreementStatus status,) = serviceAgreement.agreements(agreementId);
        assertEq(uint8(status), uint8(IServiceAgreement.AgreementStatus.Disputed), "Status should be Disputed");
    }

    /// @notice Test resolving a dispute successfully
    function test_ResolveDispute_Success() public {
        // Impersonate the DisputeResolution contract
        vm.prank(disputeResolution);

        // Expect events:
        // - FundsDistributedAfterDispute from PaymentManager (depends on ruling)
        // - AgreementDisputeResolved from ServiceAgreement
        vm.expectEmit(true, false, false, true);
        // Let's assume ClientFavored ruling (all funds to client)
        emit FundsDistributedAfterDispute(agreementId, 100, 0);
        
        vm.expectEmit(true, false, false, true);
        emit AgreementDisputeResolved(agreementId, IPaymentManager.Ruling.ClientFavored);

        serviceAgreement.resolveDispute(agreementId, IPaymentManager.Ruling.ClientFavored);

        (,,,,,IServiceAgreement.AgreementStatus statusAfter,) = serviceAgreement.agreements(agreementId);
        assertEq(uint8(statusAfter), uint8(IServiceAgreement.AgreementStatus.DisputeResolved), "Status should be DisputeResolved");

        // Check escrow empty after distribution
        uint256 escrowBalance = paymentManager.escrow(agreementId);
        assertEq(escrowBalance, 0, "Escrow should be empty after distribution");
    }

    /// @notice Test resolveDispute revert if not DisputeResolution caller
    function test_ResolveDispute_RevertIf_NotDisputeResolution() public {
        vm.prank(nonParticipant);
        vm.expectRevert("Only DisputeResolution can call");
        serviceAgreement.resolveDispute(agreementId, IPaymentManager.Ruling.ClientFavored);
    }

    /// @notice Test resolveDispute revert if not Disputed
    function test_ResolveDispute_RevertIf_NotDisputed() public {
        // Move agreement to CompletedAccepted to break conditions
        // We'll create a new agreement and move it to another status
        uint256 newAg = createAgreementHelper(client1, serviceId, provider1, 100);
        acceptAgreementHelper(provider1, newAg);
        depositFundsHelper(newAg);
        completeAgreementHelper(provider1, newAg);

        vm.prank(client1);
        serviceAgreement.acceptCompletedAgreement(newAg); // now CompletedAccepted, not Disputed

        vm.prank(disputeResolution);
        vm.expectRevert("Must be Disputed before resolving");
        serviceAgreement.resolveDispute(newAg, IPaymentManager.Ruling.ClientFavored);
    }

    /// @notice Test resolveDispute revert if agreement not found
    function test_ResolveDispute_RevertIf_AgreementNotFound() public {
        vm.prank(disputeResolution);
        vm.expectRevert("Agreement not found");
        serviceAgreement.resolveDispute(999, IPaymentManager.Ruling.ClientFavored);
    }

    /// @notice Test resolveDispute revert if invalid ruling
    function test_ResolveDispute_RevertIf_InvalidRuling() public {
        // Ruling.None is invalid (depends on your implementation)
        vm.prank(disputeResolution);
        vm.expectRevert("Invalid ruling");
        serviceAgreement.resolveDispute(agreementId, IPaymentManager.Ruling.None);
    }
}
