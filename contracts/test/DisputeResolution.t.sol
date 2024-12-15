// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {UserRegistry} from "../src/UserRegistry.sol";
import {ServiceListing} from "../src/ServiceListing.sol";
import {ServiceAgreement} from "../src/ServiceAgreement.sol";
import {PaymentManager} from "../src/PaymentManager.sol";
import {DisputeResolution} from "../src/DisputeResolution.sol";
import {IServiceAgreement} from "../src/interfaces/IServiceAgreement.sol";
import {IPaymentManager} from "../src/interfaces/IPaymentManager.sol";

/// @title DisputeResolutionBaseTest
/// @notice Base test contract for DisputeResolution, similar to UserRegistryBaseTest structure.
abstract contract DisputeResolutionBaseTest is Test {
    event ServiceAgreementAddressSet(address indexed newServiceAgreement);
    event ArbitratorSet(address indexed newArbitrator);

    UserRegistry public userRegistry;
    ServiceListing public serviceListing;
    ServiceAgreement public serviceAgreement;
    PaymentManager public paymentManager;
    DisputeResolution public disputeResolution;

    address owner = address(this);
    address provider1 = address(2);
    address client1 = address(3);
    address nonParticipant = address(4);
    address arbitrator = address(5);

    uint256 serviceId;

    /// @notice Setup runs before each test method
    function setUp() public virtual {
        userRegistry = new UserRegistry();
        serviceListing = new ServiceListing();
        serviceListing.setUserRegistry(address(userRegistry));

        vm.prank(provider1);
        userRegistry.registerUser();

        paymentManager = new PaymentManager();
        serviceAgreement = new ServiceAgreement();
        serviceAgreement.setServiceListingAddress(address(serviceListing));
        serviceAgreement.setPaymentManagerAddress(address(paymentManager));
        paymentManager.setServiceAgreementAddress(address(serviceAgreement));

        vm.prank(provider1);
        serviceId = serviceListing.createService(100); // 100 wei

        disputeResolution = new DisputeResolution();
    }

    /// @notice Helper: create agreement (Proposed)
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
        paymentManager.depositFunds{value:amount}(agreementId);
    }

    /// @notice Helper: complete agreement (Paid -> Completed)
    function completeAgreementHelper(address provider, uint256 agreementId) internal {
        vm.prank(provider);
        serviceAgreement.completeAgreement(agreementId);
    }
}

/// @title DisputeResolutionSetServiceAgreementTest
/// @notice Tests setServiceAgreementAddress of DisputeResolution
contract DisputeResolutionSetServiceAgreementTest is DisputeResolutionBaseTest {

    /// @notice Test setting ServiceAgreement successfully
    function test_SetServiceAgreementAddress_Success() public {
        address newSA = address(0x9999);
        vm.expectEmit(true, false, false, false);
        emit ServiceAgreementAddressSet(newSA);
        disputeResolution.setServiceAgreementAddress(newSA);

        IServiceAgreement sa = disputeResolution.serviceAgreement();
        assertEq(address(sa), newSA, "ServiceAgreement updated");
    }

    /// @notice Test revert if not owner
    function test_SetServiceAgreementAddress_RevertIf_NotOwner() public {
        vm.prank(nonParticipant);
        vm.expectRevert("Only owner");
        disputeResolution.setServiceAgreementAddress(address(0x9999));
    }

    /// @notice Test revert if invalid address
    function test_SetServiceAgreementAddress_RevertIf_InvalidAddress() public {
        vm.expectRevert("Invalid ServiceAgreement address");
        disputeResolution.setServiceAgreementAddress(address(0));
    }
}

/// @title DisputeResolutionSetArbitratorTest
/// @notice Tests setArbitrator function of DisputeResolution
contract DisputeResolutionSetArbitratorTest is DisputeResolutionBaseTest {

    /// @notice Test setting arbitrator successfully
    function test_SetArbitrator_Success() public {
        vm.expectEmit(true, false, false, false);
        emit ArbitratorSet(arbitrator);
        disputeResolution.setArbitrator(arbitrator);

        address arb = disputeResolution.arbitrator();
        assertEq(arb, arbitrator, "Arbitrator updated");
    }

    /// @notice Test revert if not owner
    function test_SetArbitrator_RevertIf_NotOwner() public {
        vm.prank(nonParticipant);
        vm.expectRevert("Only owner");
        disputeResolution.setArbitrator(arbitrator);
    }

    /// @notice Test revert if invalid address
    function test_SetArbitrator_RevertIf_InvalidAddress() public {
        vm.expectRevert("Invalid arbitrator address");
        disputeResolution.setArbitrator(address(0));
    }
}

/// @title DisputeResolutionRaiseDisputeTest
/// @notice Tests the raiseDispute function of DisputeResolution
/// @dev Now that disputeCompletedAgreement can only be called by DisputeResolution,
/// and raiseDispute from DisputeResolution should call disputeCompletedAgreement internally,
/// we can have a success scenario if caller is participant and agreement is Completed.
contract DisputeResolutionRaiseDisputeTest is DisputeResolutionBaseTest {
    uint256 agreementId;

    function setUp() public override {
        super.setUp();
        disputeResolution.setServiceAgreementAddress(address(serviceAgreement));
        // Set DisputeResolution in ServiceAgreement (assuming there's a setDisputeResolutionAddress in ServiceAgreement)
        vm.prank(owner);
        serviceAgreement.setDisputeResolutionAddress(address(disputeResolution));

        agreementId = createAgreementHelper(client1, serviceId, provider1, 100);
        acceptAgreementHelper(provider1, agreementId);
    }

    /// @notice Test revert scenarios for raiseDispute
    function test_RaiseDispute_RevertIf_NotParticipantOrNotCompleted() public {
        // Make agreement Completed
        depositFundsHelper(client1, agreementId,100);
        completeAgreementHelper(provider1, agreementId);
        // Now Completed

        // Non-participant tries
        vm.prank(nonParticipant);
        vm.expectRevert("Caller not participant");
        disputeResolution.raiseDispute(agreementId);

        // Another agreement still Proposed
        uint256 newAg = createAgreementHelper(client1, serviceId, provider1,100);
        // newAg is Proposed, not Completed
        vm.prank(client1);
        vm.expectRevert("Must be Completed to dispute");
        disputeResolution.raiseDispute(newAg);
    }

    /// @notice Test raiseDispute success if called by a participant (client or provider) and agreement is Completed
    function test_RaiseDispute_Success() public {
        depositFundsHelper(client1, agreementId,100);
        completeAgreementHelper(provider1, agreementId);

        // Now Completed, caller is participant (client)
        vm.prank(client1);
        disputeResolution.raiseDispute(agreementId);

        (,,,,,IServiceAgreement.AgreementStatus status,) = serviceAgreement.agreements(agreementId);
        assertEq(uint8(status), uint8(IServiceAgreement.AgreementStatus.Disputed), "Should be Disputed");
    }
}

/// @title DisputeResolutionResolveDisputeTest
/// @notice Tests the resolveDispute function of DisputeResolution
/// @dev With the new logic allowing DisputeResolution to call disputeCompletedAgreement,
/// we can now reach a Disputed state and test a success scenario for resolveDispute.
contract DisputeResolutionResolveDisputeTest is DisputeResolutionBaseTest {
    uint256 agreementId;

    function setUp() public override {
        super.setUp();
        disputeResolution.setServiceAgreementAddress(address(serviceAgreement));
        vm.prank(owner);
        serviceAgreement.setDisputeResolutionAddress(address(disputeResolution));

        agreementId = createAgreementHelper(client1, serviceId, provider1,100);
        acceptAgreementHelper(provider1, agreementId);
        depositFundsHelper(client1, agreementId,100);
        completeAgreementHelper(provider1, agreementId);

        // Raise dispute by participant (client)
        vm.prank(client1);
        disputeResolution.raiseDispute(agreementId);
        // Now Disputed
    }

    /// @notice Test revert if not arbitrator calls resolveDispute
    function test_ResolveDispute_RevertIf_NotArbitrator() public {
        vm.prank(nonParticipant);
        vm.expectRevert("Only arbitrator");
        disputeResolution.resolveDispute(agreementId, IPaymentManager.Ruling.ClientFavored);
    }

    /// @notice Test resolveDispute success if called by arbitrator
    function test_ResolveDispute_Success() public {
        disputeResolution.setArbitrator(arbitrator);

        vm.prank(arbitrator);
        disputeResolution.resolveDispute(agreementId, IPaymentManager.Ruling.ClientFavored);

        (,,,,,IServiceAgreement.AgreementStatus status,) = serviceAgreement.agreements(agreementId);
        assertEq(uint8(status), uint8(IServiceAgreement.AgreementStatus.DisputeResolved), "Should be DisputeResolved");
    }
}
