// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {UserRegistry} from "../src/UserRegistry.sol";
import {ServiceListing} from "../src/ServiceListing.sol";
import {ServiceAgreement} from "../src/ServiceAgreement.sol";
import {PaymentManager} from "../src/PaymentManager.sol";
import {DisputeResolution} from "../src/DisputeResolution.sol";
import {ReputationManager} from "../src/ReputationManager.sol";
import {IServiceAgreement} from "../src/interfaces/IServiceAgreement.sol";
import {IPaymentManager} from "../src/interfaces/IPaymentManager.sol";

/// @title ReputationManagerBaseTest
/// @notice Base test contract for ReputationManager, setting up environment similar to UserRegistryBaseTest.
abstract contract ReputationManagerBaseTest is Test {
    event ServiceAgreementAddressSet(address indexed newServiceAgreement);
    event ArbitratorSet(address indexed newArbitrator);
    event FeedbackSubmitted(uint256 indexed agreementId, address indexed client, address indexed provider, uint8 rating);

    UserRegistry public userRegistry;
    ServiceListing public serviceListing;
    ServiceAgreement public serviceAgreement;
    PaymentManager public paymentManager;
    DisputeResolution public disputeResolution;
    ReputationManager public reputationManager;

    address owner = address(this);
    address provider1 = address(2);
    address client1 = address(3);
    address nonParticipant = address(4);
    address arbitrator = address(5);

    uint256 serviceId;

    /// @notice Setup runs before each test method
    function setUp() public virtual {
        // Deploy UserRegistry and ServiceListing
        userRegistry = new UserRegistry();
        serviceListing = new ServiceListing();
        serviceListing.setUserRegistry(address(userRegistry));

        // Register provider
        vm.prank(provider1);
        userRegistry.registerUser();

        // Deploy PaymentManager and ServiceAgreement
        paymentManager = new PaymentManager();
        serviceAgreement = new ServiceAgreement();
        serviceAgreement.setServiceListingAddress(address(serviceListing));
        serviceAgreement.setPaymentManagerAddress(address(paymentManager));
        paymentManager.setServiceAgreementAddress(address(serviceAgreement));

        // Create a service
        vm.prank(provider1);
        serviceId = serviceListing.createService(100); // 100 wei

        // Deploy DisputeResolution
        disputeResolution = new DisputeResolution();
        disputeResolution.setServiceAgreementAddress(address(serviceAgreement));

        // Deploy ReputationManager
        reputationManager = new ReputationManager();
        vm.prank(owner);
        reputationManager.setServiceAgreementAddress(address(serviceAgreement));
    }

    /// @notice Helper: create an agreement (Proposed)
    function createAgreementHelper(address client, uint256 _serviceId, address _provider, uint256 _amount) internal returns (uint256) {
        vm.prank(client);
        return serviceAgreement.createAgreement(_serviceId, _provider, _amount);
    }

    /// @notice Helper: accept agreement (Proposed -> Accepted)
    function acceptAgreementHelper(address provider, uint256 agreementId) internal {
        vm.prank(provider);
        serviceAgreement.acceptAgreement(agreementId);
    }

    /// @notice Helper: deposit funds (client)
    function depositFundsHelper(address client, uint256 agreementId, uint256 amount) internal {
        vm.deal(client, amount);
        vm.prank(client);
        paymentManager.depositFunds{value: amount}(agreementId);
    }

    /// @notice Helper: complete agreement (Paid -> Completed)
    function completeAgreementHelper(address provider, uint256 agreementId) internal {
        vm.prank(provider);
        serviceAgreement.completeAgreement(agreementId);
    }

    /// @notice Helper: accept completed agreement (Completed -> CompletedAccepted)
    function acceptCompletedAgreementHelper(address client, uint256 agreementId) internal {
        vm.prank(client);
        serviceAgreement.acceptCompletedAgreement(agreementId);
    }

    /// @notice Helper: raise dispute via DisputeResolution (Completed -> Disputed)
    function raiseDisputeHelper(uint256 agreementId) internal {
        vm.prank(client1);
        disputeResolution.raiseDispute(agreementId);
    }

    /// @notice Helper: resolve dispute via DisputeResolution (Disputed -> DisputeResolved)
    function resolveDisputeHelper(uint256 agreementId, IPaymentManager.Ruling ruling) internal {
        vm.prank(arbitrator);
        disputeResolution.resolveDispute(agreementId, ruling);
    }
}

/// @title ReputationManagerSetServiceAgreementAddressTest
/// @notice Tests setServiceAgreementAddress function of ReputationManager
contract ReputationManagerSetServiceAgreementAddressTest is ReputationManagerBaseTest {

    /// @notice Tests setting ServiceAgreement address successfully
    function test_SetServiceAgreementAddress_Success() public {
        address newSA = address(0x9999);
        vm.prank(owner);
        vm.expectEmit(true, false, false, false);
        emit ServiceAgreementAddressSet(newSA);
        reputationManager.setServiceAgreementAddress(newSA);

        IServiceAgreement sa = reputationManager.serviceAgreement();
        assertEq(address(sa), newSA, "ServiceAgreement updated");
    }

    /// @notice Tests revert if not owner
    function test_SetServiceAgreementAddress_RevertIf_NotOwner() public {
        address newSA = address(0x9999);
        vm.prank(nonParticipant);
        vm.expectRevert("Only owner");
        reputationManager.setServiceAgreementAddress(newSA);
    }

    /// @notice Tests revert if invalid address
    function test_SetServiceAgreementAddress_RevertIf_InvalidAddress() public {
        vm.prank(owner);
        vm.expectRevert("Invalid ServiceAgreement address");
        reputationManager.setServiceAgreementAddress(address(0));
    }
}

/// @title ReputationManagerSubmitFeedbackTest
/// @notice Tests the submitFeedback function of ReputationManager
contract ReputationManagerSubmitFeedbackTest is ReputationManagerBaseTest {
    uint256 agreementId;

    function setUp() public override {
        super.setUp();

        // Create and accept agreement
        agreementId = createAgreementHelper(client1, serviceId, provider1, 100);
        acceptAgreementHelper(provider1, agreementId);
    }

    /// @notice Test revert if feedback already submitted for the agreement
    function test_SubmitFeedback_RevertIf_AlreadySubmitted() public {
        // Make agreement CompletedAccepted
        depositFundsHelper(client1, agreementId, 100);
        completeAgreementHelper(provider1, agreementId);
        acceptCompletedAgreementHelper(client1, agreementId);

        // Submit first feedback
        vm.prank(client1);
        reputationManager.submitFeedback(agreementId, 5);

        // Attempt to submit second feedback
        vm.prank(client1);
        vm.expectRevert("Feedback already submitted for this agreement");
        reputationManager.submitFeedback(agreementId, 4);
    }

    /// @notice Test revert if agreement is not in final feedback state
    function test_SubmitFeedback_RevertIf_NotFinalState() public {
        // Agreement is Accepted but not Completed or DisputeResolved
        vm.prank(client1);
        vm.expectRevert("Agreement not in final feedback state");
        reputationManager.submitFeedback(agreementId, 5);
    }

    /// @notice Test revert if caller is not a participant (only client can submit)
    function test_SubmitFeedback_RevertIf_NotParticipant() public {
        // Make agreement CompletedAccepted
        depositFundsHelper(client1, agreementId, 100);
        completeAgreementHelper(provider1, agreementId);
        acceptCompletedAgreementHelper(client1, agreementId);

        // Non-participant attempts to submit feedback
        vm.prank(nonParticipant);
        vm.expectRevert("Only client can submit feedback");
        reputationManager.submitFeedback(agreementId, 5);
    }

    /// @notice Test revert if rating is out of bounds
    function test_SubmitFeedback_RevertIf_InvalidRating() public {
        // Make agreement CompletedAccepted
        depositFundsHelper(client1, agreementId, 100);
        completeAgreementHelper(provider1, agreementId);
        acceptCompletedAgreementHelper(client1, agreementId);

        // Invalid rating (0)
        vm.prank(client1);
        vm.expectRevert("Invalid rating");
        reputationManager.submitFeedback(agreementId, 0);

        // Invalid rating (6)
        vm.prank(client1);
        vm.expectRevert("Invalid rating");
        reputationManager.submitFeedback(agreementId, 6);
    }

    /// @notice Test successful feedback submission by client
    function test_SubmitFeedback_Success_Client() public {
        // Make agreement CompletedAccepted
        depositFundsHelper(client1, agreementId, 100);
        completeAgreementHelper(provider1, agreementId);
        acceptCompletedAgreementHelper(client1, agreementId);

        // Submit feedback as client
        vm.prank(client1);
        vm.expectEmit(true, true, true, true);
        emit FeedbackSubmitted(agreementId, client1, provider1, 5);
        reputationManager.submitFeedback(agreementId, 5);

        // Check reputation
        uint256 totalScore_ = reputationManager.totalScore(provider1);
        uint256 totalRatings_ = reputationManager.totalRatings(provider1);
        assertEq(totalScore_, 5, "Provider's total score should be 5");
        assertEq(totalRatings_, 1, "Provider's total ratings should be 1");

        // Check feedbackSubmitted
        bool feedback = reputationManager.feedbackSubmitted(agreementId);
        assertTrue(feedback, "Feedback should be marked as submitted");
    }
}

/// @title ReputationManagerGetAverageRatingTest
/// @notice Tests the getAverageRating function of ReputationManager
contract ReputationManagerGetAverageRatingTest is ReputationManagerBaseTest {
    uint256 agreementId1;
    uint256 agreementId2;

    function setUp() public override {
        super.setUp();

        // Create and accept first agreement
        agreementId1 = createAgreementHelper(client1, serviceId, provider1, 100);
        acceptAgreementHelper(provider1, agreementId1);

        // Create and accept second agreement
        agreementId2 = createAgreementHelper(client1, serviceId, provider1, 100);
        acceptAgreementHelper(provider1, agreementId2);

        // Make agreements CompletedAccepted
        depositFundsHelper(client1, agreementId1, 100);
        completeAgreementHelper(provider1, agreementId1);
        acceptCompletedAgreementHelper(client1, agreementId1);

        depositFundsHelper(client1, agreementId2, 100);
        completeAgreementHelper(provider1, agreementId2);
        acceptCompletedAgreementHelper(client1, agreementId2);
    }

    /// @notice Test average rating calculation
    function test_GetAverageRating_Success() public {
        // Submit feedback for agreement1
        vm.prank(client1);
        reputationManager.submitFeedback(agreementId1, 5); // Provider gets 5

        // Submit feedback for agreement2
        vm.prank(client1);
        reputationManager.submitFeedback(agreementId2, 3); // Provider gets 3

        // Get average rating
        uint256 avgRating = reputationManager.getAverageRating(provider1);
        assertEq(avgRating, 4, "Average rating should be 4");

        // Get average rating for a user with no ratings
        uint256 avgRatingNone = reputationManager.getAverageRating(nonParticipant);
        assertEq(avgRatingNone, 0, "Average rating should be 0 for user with no ratings");
    }

    /// @notice Test average rating with single rating
    function test_GetAverageRating_SingleRating() public {
        // Submit feedback for agreement1
        vm.prank(client1);
        reputationManager.submitFeedback(agreementId1, 4); // Provider gets 4

        // Get average rating
        uint256 avgRating = reputationManager.getAverageRating(provider1);
        assertEq(avgRating, 4, "Average rating should be 4");
    }

    /// @notice Test average rating with no ratings
    function test_GetAverageRating_NoRatings() public view {
        // Get average rating for provider without feedback
        uint256 avgRating = reputationManager.getAverageRating(provider1);
        assertEq(avgRating, 0, "Average rating should be 0 when no ratings submitted");
    }
}
