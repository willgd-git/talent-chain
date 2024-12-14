// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {UserRegistry} from "../src/UserRegistry.sol";
import {ServiceListing} from "../src/ServiceListing.sol";
import {ServiceAgreement} from "../src/ServiceAgreement.sol";

/// @title ServiceAgreementBaseTest
/// @notice Base test contract for ServiceAgreement. Sets up UserRegistry, ServiceListing, and ServiceAgreement.
/// @dev Provides helper methods for repetitive tasks.
abstract contract ServiceAgreementBaseTest is Test {
    event AgreementCreated(uint256 indexed agreementId, uint256 indexed serviceId, address indexed client, address provider, uint256 amount);
    event AgreementAcceptedByProvider(uint256 indexed agreementId);
    event AgreementPaid(uint256 indexed agreementId);
    event AgreementCompleted(uint256 indexed agreementId);
    event AgreementCancelled(uint256 indexed agreementId);
    event AgreementCompletedAccepted(uint256 indexed agreementId);
    event AgreementDisputed(uint256 indexed agreementId);

    UserRegistry public userRegistry;
    ServiceListing public serviceListing;
    ServiceAgreement public serviceAgreement;

    address owner = address(1);
    address provider1 = address(2);
    address client1 = address(3);
    address nonParticipant = address(4);

    uint256 serviceId;

    function setUp() public virtual {
        // Deploy UserRegistry
        vm.startPrank(owner);
        userRegistry = new UserRegistry();
        vm.stopPrank();

        // Deploy ServiceListing with UserRegistry
        vm.prank(owner);
        serviceListing = new ServiceListing(address(userRegistry));

        // Deploy ServiceAgreement with ServiceListing
        vm.prank(owner);
        serviceAgreement = new ServiceAgreement(address(serviceListing));

        // Register provider
        vm.prank(provider1);
        userRegistry.registerUser();

        // Provider creates a service
        vm.prank(provider1);
        serviceId = serviceListing.createService(100);
    }

    /// @notice Helper to register user
    function registerUser(address user) internal {
        vm.prank(user);
        userRegistry.registerUser();
    }

    /// @notice Helper to create an agreement
    function createAgreementHelper(address client, uint256 _serviceId, address _provider, uint256 _amount) internal returns (uint256 agreementId) {
        vm.prank(client);
        agreementId = serviceAgreement.createAgreement(_serviceId, _provider, _amount);
    }

    /// @notice Helper to accept an agreement (by provider)
    function acceptAgreementHelper(address provider, uint256 agreementId) internal {
        vm.prank(provider);
        serviceAgreement.acceptAgreement(agreementId);
    }

    /// @notice Helper to mark agreement as paid
    function markPaidHelper(uint256 agreementId) internal {
        // Assume this is called by an authorized entity like PaymentManager
        vm.prank(owner);
        serviceAgreement.markAsPaid(agreementId);
    }

    /// @notice Helper to complete agreement (by provider)
    function completeAgreementHelper(address provider, uint256 agreementId) internal {
        vm.prank(provider);
        serviceAgreement.completeAgreement(agreementId);
    }

    /// @notice Warp time forward
    function warpForward(uint256 secondsToWarp) internal {
        vm.warp(block.timestamp + secondsToWarp);
    }
}

/// @title ServiceAgreementCreateTest
/// @notice Tests creating agreements
contract ServiceAgreementCreateTest is ServiceAgreementBaseTest {

    function test_CreateAgreement_Success() public {
        vm.prank(client1);
        vm.expectEmit(true, true, false, true);
        emit AgreementCreated(1, serviceId, client1, provider1, 50);
        uint256 agreementId = serviceAgreement.createAgreement(serviceId, provider1, 50);

        (uint256 aId, uint256 sId, address client, address prov, uint256 amount, ServiceAgreement.AgreementStatus status,) 
            = serviceAgreement.agreements(agreementId);
        
        assertEq(aId, 1, "agreementId should be 1");
        assertEq(sId, serviceId, "serviceId should match");
        assertEq(client, client1, "client should match");
        assertEq(prov, provider1, "provider should match");
        assertEq(amount, 50, "amount should match");
        assertEq(uint8(status), uint8(ServiceAgreement.AgreementStatus.Proposed), "status should be Proposed");
    }

    function test_CreateAgreement_RevertIf_AmountZero() public {
        vm.prank(client1);
        vm.expectRevert("Amount must be greater than 0");
        serviceAgreement.createAgreement(serviceId, provider1, 0);
    }

    function test_CreateAgreement_RevertIf_InvalidService() public {
        vm.prank(client1);
        vm.expectRevert("Invalid serviceId");
        serviceAgreement.createAgreement(999, provider1, 50);
    }

    function test_CreateAgreement_RevertIf_ProviderMismatch() public {
        address provider2 = address(5);
        vm.prank(provider2);
        userRegistry.registerUser();
        vm.prank(provider2);
        serviceListing.createService(200);

        vm.prank(client1);
        vm.expectRevert("Provider mismatch");
        serviceAgreement.createAgreement(serviceId, provider2, 50);
    }
}

/// @title ServiceAgreementUpdateTest
/// @notice Tests updating the agreement amount only in Proposed state
contract ServiceAgreementUpdateTest is ServiceAgreementBaseTest {
    uint256 agreementId;

    function setUp() public override {
        super.setUp();
        agreementId = createAgreementHelper(client1, serviceId, provider1, 50);
    }

    function test_UpdateAgreementAmount_Success() public {
        vm.prank(client1);
        serviceAgreement.updateAgreementAmount(agreementId, 60);

        (,,,,uint256 amount,ServiceAgreement.AgreementStatus status,) = serviceAgreement.agreements(agreementId);
        assertEq(amount, 60, "Amount should be updated");
        assertEq(uint8(status), uint8(ServiceAgreement.AgreementStatus.Proposed), "status should still be Proposed");
    }

    function test_UpdateAgreementAmount_RevertIf_AmountZero() public {
        vm.prank(provider1);
        vm.expectRevert("Amount must be greater than 0");
        serviceAgreement.updateAgreementAmount(agreementId, 0);
    }

    function test_UpdateAgreementAmount_RevertIf_NotParticipant() public {
        vm.prank(nonParticipant);
        vm.expectRevert("Not a participant");
        serviceAgreement.updateAgreementAmount(agreementId, 60);
    }

    function test_UpdateAgreementAmount_RevertIf_NotProposed() public {
        acceptAgreementHelper(provider1, agreementId);
        vm.prank(client1);
        vm.expectRevert("Can only edit in Proposed state");
        serviceAgreement.updateAgreementAmount(agreementId, 60);
    }
}

/// @title ServiceAgreementAcceptTest
/// @notice Tests agreement acceptance by provider
contract ServiceAgreementAcceptTest is ServiceAgreementBaseTest {
    uint256 agreementId;

    function setUp() public override {
        super.setUp();
        agreementId = createAgreementHelper(client1, serviceId, provider1, 50);
    }

    function test_AcceptAgreement_Success() public {
        vm.prank(provider1);
        vm.expectEmit(true, false, false, true);
        emit AgreementAcceptedByProvider(agreementId);
        serviceAgreement.acceptAgreement(agreementId);

        (,,,,,ServiceAgreement.AgreementStatus status,) = serviceAgreement.agreements(agreementId);
        assertEq(uint8(status), uint8(ServiceAgreement.AgreementStatus.Accepted), "status should be Accepted");
    }

    function test_AcceptAgreement_RevertIf_NotProvider() public {
        vm.prank(client1);
        vm.expectRevert("Only provider can accept");
        serviceAgreement.acceptAgreement(agreementId);
    }

    function test_AcceptAgreement_RevertIf_WrongStatus() public {
        // Cancel first
        vm.prank(client1);
        serviceAgreement.cancelAgreement(agreementId);

        vm.prank(provider1);
        vm.expectRevert("Wrong status");
        serviceAgreement.acceptAgreement(agreementId);
    }
}

/// @title ServiceAgreementPaymentAndCompletionTest
/// @notice Tests marking agreement as paid and completing by provider
contract ServiceAgreementPaymentAndCompletionTest is ServiceAgreementBaseTest {
    uint256 agreementId;

    function setUp() public override {
        super.setUp();
        agreementId = createAgreementHelper(client1, serviceId, provider1, 50);
        acceptAgreementHelper(provider1, agreementId);
    }

    function test_MarkAsPaid_Success() public {
        vm.prank(owner);
        vm.expectEmit(true, false, false, true);
        emit AgreementPaid(agreementId);
        serviceAgreement.markAsPaid(agreementId);

        (,,,,,ServiceAgreement.AgreementStatus status,) = serviceAgreement.agreements(agreementId);
        assertEq(uint8(status), uint8(ServiceAgreement.AgreementStatus.Paid), "status should be Paid");
    }

    function test_MarkAsPaid_RevertIf_NotAccepted() public {
        uint256 newAgree = createAgreementHelper(client1, serviceId, provider1, 50);
        vm.prank(owner);
        vm.expectRevert("Must be Accepted before Paid");
        serviceAgreement.markAsPaid(newAgree);
    }

    function test_CompleteAgreement_Success() public {
        markPaidHelper(agreementId);
        vm.prank(provider1);
        vm.expectEmit(true, false, false, true);
        emit AgreementCompleted(agreementId);
        serviceAgreement.completeAgreement(agreementId);

        (,,,,,ServiceAgreement.AgreementStatus status,) = serviceAgreement.agreements(agreementId);
        assertEq(uint8(status), uint8(ServiceAgreement.AgreementStatus.Completed), "status should be Completed");
    }

    function test_CompleteAgreement_RevertIf_NotProvider() public {
        markPaidHelper(agreementId);
        vm.prank(client1);
        vm.expectRevert("Only provider can complete");
        serviceAgreement.completeAgreement(agreementId);
    }

    function test_CompleteAgreement_RevertIf_NotPaid() public {
        vm.prank(provider1);
        vm.expectRevert("Must be Paid before Completed");
        serviceAgreement.completeAgreement(agreementId);
    }
}

/// @title ServiceAgreementCompletionAcceptAndDisputeTest
/// @notice Tests client's acceptance or dispute after completion, and timeout finalization
contract ServiceAgreementCompletionAcceptAndDisputeTest is ServiceAgreementBaseTest {
    uint256 agreementId;

    function setUp() public override {
        super.setUp();
        agreementId = createAgreementHelper(client1, serviceId, provider1, 50);
        acceptAgreementHelper(provider1, agreementId);
        markPaidHelper(agreementId);
        completeAgreementHelper(provider1, agreementId);
    }

    function test_AcceptCompletedAgreement_Success() public {
        vm.prank(client1);
        vm.expectEmit(true, false, false, true);
        emit AgreementCompletedAccepted(agreementId);
        serviceAgreement.acceptCompletedAgreement(agreementId);

        (,,,,,ServiceAgreement.AgreementStatus status,) = serviceAgreement.agreements(agreementId);
        assertEq(uint8(status), uint8(ServiceAgreement.AgreementStatus.CompletedAccepted), "status should be CompletedAccepted");
    }

    function test_AcceptCompletedAgreement_RevertIf_NotClient() public {
        vm.prank(provider1);
        vm.expectRevert("Only client can accept");
        serviceAgreement.acceptCompletedAgreement(agreementId);
    }

    function test_AcceptCompletedAgreement_RevertIf_NotCompleted() public {
        uint256 newAgree = createAgreementHelper(client1, serviceId, provider1, 50);
        acceptAgreementHelper(provider1, newAgree);
        markPaidHelper(newAgree);
        // Not completed yet
        vm.prank(client1);
        vm.expectRevert("Must be Completed before accepted");
        serviceAgreement.acceptCompletedAgreement(newAgree);
    }

    function test_DisputeCompletedAgreement_Success() public {
        vm.prank(client1);
        vm.expectEmit(true, false, false, true);
        emit AgreementDisputed(agreementId);
        serviceAgreement.disputeCompletedAgreement(agreementId);

        (,,,,,ServiceAgreement.AgreementStatus status,) = serviceAgreement.agreements(agreementId);
        assertEq(uint8(status), uint8(ServiceAgreement.AgreementStatus.Disputed), "status should be Disputed");
    }

    function test_DisputeCompletedAgreement_RevertIf_NotClient() public {
        vm.prank(provider1);
        vm.expectRevert("Only client can dispute");
        serviceAgreement.disputeCompletedAgreement(agreementId);
    }

    function test_DisputeCompletedAgreement_RevertIf_NotCompleted() public {
        uint256 newAgree = createAgreementHelper(client1, serviceId, provider1, 50);
        acceptAgreementHelper(provider1, newAgree);
        markPaidHelper(newAgree);
        // not completed yet
        vm.prank(client1);
        vm.expectRevert("Must be Completed before dispute");
        serviceAgreement.disputeCompletedAgreement(newAgree);
    }

    function test_FinalizeCompletionIfTimeout_Success() public {
        warpForward(serviceAgreement.completionAcceptanceTimeout() + 1);

        vm.expectEmit(true, false, false, true);
        emit AgreementCompletedAccepted(agreementId);
        serviceAgreement.finalizeCompletionIfTimeout(agreementId);

        (,,,,,ServiceAgreement.AgreementStatus status,) = serviceAgreement.agreements(agreementId);
        assertEq(uint8(status), uint8(ServiceAgreement.AgreementStatus.CompletedAccepted), "status should be CompletedAccepted");
    }

    function test_FinalizeCompletionIfTimeout_RevertIf_NotCompleted() public {
        uint256 newAgree = createAgreementHelper(client1, serviceId, provider1, 50);
        acceptAgreementHelper(provider1, newAgree);
        // not completed
        vm.expectRevert("Must be Completed");
        serviceAgreement.finalizeCompletionIfTimeout(newAgree);
    }

    function test_FinalizeCompletionIfTimeout_RevertIf_NotTimeoutYet() public {
        vm.expectRevert("Timeout not reached");
        serviceAgreement.finalizeCompletionIfTimeout(agreementId);
    }
}

/// @title ServiceAgreementCancelTest
/// @notice Tests the cancellation logic of the agreement
contract ServiceAgreementCancelTest is ServiceAgreementBaseTest {
    uint256 agreementId;

    function setUp() public override {
        super.setUp();
        agreementId = createAgreementHelper(client1, serviceId, provider1, 50);
    }

    function test_CancelAgreement_Success_Proposed() public {
        vm.prank(client1);
        vm.expectEmit(true, false, false, true);
        emit AgreementCancelled(agreementId);
        serviceAgreement.cancelAgreement(agreementId);

        (,,,,,ServiceAgreement.AgreementStatus status,) = serviceAgreement.agreements(agreementId);
        assertEq(uint8(status), uint8(ServiceAgreement.AgreementStatus.Cancelled), "status should be Cancelled");
    }

    function test_CancelAgreement_Success_Accepted() public {
        acceptAgreementHelper(provider1, agreementId);

        vm.prank(provider1);
        vm.expectEmit(true, false, false, true);
        emit AgreementCancelled(agreementId);
        serviceAgreement.cancelAgreement(agreementId);

        (,,,,,ServiceAgreement.AgreementStatus status,) = serviceAgreement.agreements(agreementId);
        assertEq(uint8(status), uint8(ServiceAgreement.AgreementStatus.Cancelled), "status should be Cancelled");
    }

    function test_CancelAgreement_RevertIf_NotParticipant() public {
        vm.prank(nonParticipant);
        vm.expectRevert("Not participant");
        serviceAgreement.cancelAgreement(agreementId);
    }

    function test_CancelAgreement_RevertIf_StatusAtLeastPaid() public {
        acceptAgreementHelper(provider1, agreementId);
        markPaidHelper(agreementId);

        vm.prank(client1);
        vm.expectRevert("Cannot cancel now");
        serviceAgreement.cancelAgreement(agreementId);
    }
}
