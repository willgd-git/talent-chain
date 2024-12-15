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

/// @title PaymentManagerBaseTest
/// @notice Base test contract setting up environment for PaymentManager tests.
/// @dev The test contract itself is the owner of all deployed contracts.
abstract contract PaymentManagerBaseTest is Test {
    event FundsDeposited(uint256 indexed agreementId, uint256 amount);
    event FundsReleased(uint256 indexed agreementId, uint256 amount, address indexed to);
    event FundsDistributedAfterDispute(uint256 indexed agreementId, uint256 clientAmount, uint256 providerAmount);
    event ServiceAgreementAddressSet(address indexed newServiceAgreement);

    UserRegistry public userRegistry;
    ServiceListing public serviceListing;
    ServiceAgreement public serviceAgreement;
    PaymentManager public paymentManager;

    address provider1 = address(2);
    address client1 = address(3);
    address nonParticipant = address(4);
    address disputeResolution = address(5);

    uint256 serviceId;

    /// @notice Sets up environment before each test
    function setUp() public virtual {
        userRegistry = new UserRegistry();
        serviceListing = new ServiceListing();
        serviceListing.setUserRegistry(address(userRegistry));

        // Register provider
        vm.prank(provider1);
        userRegistry.registerUser();

        paymentManager = new PaymentManager();
        serviceAgreement = new ServiceAgreement();
        serviceAgreement.setServiceListingAddress(address(serviceListing));
        serviceAgreement.setPaymentManagerAddress(address(paymentManager));

        paymentManager.setServiceAgreementAddress(address(serviceAgreement));

        vm.prank(provider1);
        serviceId = serviceListing.createService(100); // 100 wei
    }

    /// @notice Create an agreement (Proposed)
    function createAgreementHelper(address client, uint256 _serviceId, address _provider, uint256 _amount) internal returns (uint256) {
        vm.prank(client);
        return serviceAgreement.createAgreement(_serviceId, _provider, _amount);
    }

    /// @notice Accept agreement (Proposed -> Accepted)
    function acceptAgreementHelper(address provider, uint256 agreementId) internal {
        vm.prank(provider);
        serviceAgreement.acceptAgreement(agreementId);
    }

    /// @notice Complete agreement (Paid -> Completed)
    function completeAgreementHelper(address provider, uint256 agreementId) internal {
        vm.prank(provider);
        serviceAgreement.completeAgreement(agreementId);
    }

    /// @notice Dispute agreement (Completed -> Disputed)
    function disputeAgreementHelper(address client, uint256 agreementId) internal {
        vm.prank(client);
        serviceAgreement.disputeCompletedAgreement(agreementId);
    }

    /// @notice Resolve dispute scenario if needed
    function resolveDisputeHelper(uint256 agreementId, IPaymentManager.Ruling ruling, uint256 clientAmount, uint256 providerAmount) internal {
        vm.prank(address(this)); 
        serviceAgreement.setDisputeResolutionAddress(disputeResolution);

        vm.prank(disputeResolution);
        vm.expectEmit(true, false, false, true);
        emit FundsDistributedAfterDispute(agreementId, clientAmount, providerAmount);
        serviceAgreement.resolveDispute(agreementId, ruling);
    }
}

/// @title PaymentManagerDepositFundsTest
/// @notice Tests depositFunds function
contract PaymentManagerDepositFundsTest is PaymentManagerBaseTest {
    uint256 agreementId;

    function setUp() public override {
        super.setUp();
        agreementId = createAgreementHelper(client1, serviceId, provider1, 100);
        acceptAgreementHelper(provider1, agreementId);
    }

    /// @notice Tests successful deposit by client in Accepted state with exact amount
    function test_DepositFunds_Success() public {
        vm.deal(client1,100);
        vm.prank(client1);
        vm.expectEmit(true, false, false, true);
        emit FundsDeposited(agreementId, 100);
        paymentManager.depositFunds{value:100}(agreementId);

        uint256 bal = paymentManager.escrow(agreementId);
        assertEq(bal, 100, "Escrow should hold 100 wei");
        (,,,,,IServiceAgreement.AgreementStatus status,) = serviceAgreement.agreements(agreementId);
        assertEq(uint8(status), uint8(IServiceAgreement.AgreementStatus.Paid), "Should be Paid after deposit");
    }

    /// @notice Tests revert if caller is not the client
    function test_DepositFunds_RevertIf_NotClient() public {
        vm.deal(nonParticipant, 100);
        vm.prank(nonParticipant);
        vm.expectRevert("Only client can deposit");
        paymentManager.depositFunds{value:100}(agreementId);
    }

    /// @notice Tests revert if agreement is not in Accepted state
    function test_DepositFunds_RevertIf_NotAcceptedState() public {
        // Create another agreement that remains Proposed
        uint256 newAg = createAgreementHelper(client1, serviceId, provider1, 100);
        vm.deal(client1,100);
        vm.prank(client1);
        vm.expectRevert("Not depositable state");
        paymentManager.depositFunds{value:100}(newAg);
    }

    /// @notice Tests revert if incorrect amount is deposited
    function test_DepositFunds_RevertIf_IncorrectAmount() public {
        vm.deal(client1,50);
        vm.prank(client1);
        vm.expectRevert("Must deposit exact amount");
        paymentManager.depositFunds{value:50}(agreementId);
    }
}


/// @title PaymentManagerReleaseFundsTest
/// @notice Tests releaseFunds function
contract PaymentManagerReleaseFundsTest is PaymentManagerBaseTest {
    uint256 agreementId;

    function setUp() public override {
        super.setUp();
        agreementId = createAgreementHelper(client1, serviceId, provider1, 100);
        acceptAgreementHelper(provider1, agreementId);
    }

    /// @notice Tests successful releaseFunds following the normal flow:
    /// Deposit -> Paid, Complete -> Completed, AcceptCompleted -> CompletedAccepted, then releaseFunds.
    function test_ReleaseFunds_Success() public {
        vm.deal(client1,100);
        vm.prank(client1);
        paymentManager.depositFunds{value:100}(agreementId);

        uint256 providerBefore = provider1.balance;

        // Complete and accept completed
        completeAgreementHelper(provider1, agreementId);
        vm.prank(client1);
        vm.expectEmit(true, false, false, true);
        emit FundsReleased(agreementId, 100, provider1);
        serviceAgreement.acceptCompletedAgreement(agreementId);

        uint256 providerAfter = provider1.balance;
        assertEq(providerAfter, providerBefore + 100, "Provider should get 100 wei");
    }

    /// @notice Tests revert if not called by ServiceAgreement
    function test_ReleaseFunds_RevertIf_NotServiceAgreement() public {
        vm.expectRevert("Only ServiceAgreement can call");
        paymentManager.releaseFunds(agreementId);
    }

    /// @notice Tests revert if not CompletedAccepted
    function test_ReleaseFunds_RevertIf_NotCompletedAccepted() public {
        // Just deposit -> Paid, not completed or accepted
        vm.deal(client1,100);
        vm.prank(client1);
        paymentManager.depositFunds{value:100}(agreementId);
        // Now Paid but not CompletedAccepted
        vm.prank(address(serviceAgreement));
        vm.expectRevert("Not in CompletedAccepted state");
        paymentManager.releaseFunds(agreementId);
    }
}


/// @title PaymentManagerDistributeAfterDisputeTest
/// @notice Tests distributeAfterDispute function
contract PaymentManagerDistributeAfterDisputeTest is PaymentManagerBaseTest {
    uint256 agreementId;

    function setUp() public override {
        super.setUp();
        agreementId = createAgreementHelper(client1, serviceId, provider1, 100);
        acceptAgreementHelper(provider1, agreementId);
        vm.deal(client1,100);
        vm.prank(client1);
        paymentManager.depositFunds{value:100}(agreementId);
        completeAgreementHelper(provider1, agreementId);
        disputeAgreementHelper(client1, agreementId);
    }

    /// @notice Tests invalid ruling scenario
    function test_DistributeAfterDispute_RevertIf_InvalidRuling() public {
        vm.prank(address(this));
        serviceAgreement.setDisputeResolutionAddress(disputeResolution);

        vm.prank(disputeResolution);
        vm.expectRevert("Invalid ruling");
        serviceAgreement.resolveDispute(agreementId, IPaymentManager.Ruling.None);
    }

    // No no-escrow test, no scenario needed
    // No "not disputed state" test if that scenario is not relevant or always ensured by normal flow
    // If you want it, it can remain.

    /// @notice Tests successful client favored distribution
    function test_DistributeAfterDispute_Success_ClientFavored() public {
        vm.prank(address(this));
        serviceAgreement.setDisputeResolutionAddress(disputeResolution);

        vm.prank(disputeResolution);
        vm.expectEmit(true, false, false, true);
        emit FundsDistributedAfterDispute(agreementId, 100, 0);
        serviceAgreement.resolveDispute(agreementId, IPaymentManager.Ruling.ClientFavored);

        uint256 bal = paymentManager.escrow(agreementId);
        assertEq(bal, 0, "Escrow empty after distribution");
    }
}

/// @title PaymentManagerSetServiceAgreementAddressTest
/// @notice Tests setServiceAgreementAddress function
contract PaymentManagerSetServiceAgreementAddressTest is PaymentManagerBaseTest {

    /// @notice Tests setting ServiceAgreement address successfully
    function test_SetServiceAgreementAddress_Success() public {
        address newSA = address(7);
        vm.expectEmit(true, false, false, false);
        emit ServiceAgreementAddressSet(newSA);
        paymentManager.setServiceAgreementAddress(newSA);

        assertEq(address(paymentManager.serviceAgreement()), newSA, "ServiceAgreement updated");
    }

    /// @notice Tests revert if caller not owner
    function test_SetServiceAgreementAddress_RevertIf_NotOwner() public {
        address newSA = address(7);
        vm.prank(address(0x9999));
        vm.expectRevert("Only owner");
        paymentManager.setServiceAgreementAddress(newSA);
    }

    /// @notice Tests revert if invalid address
    function test_SetServiceAgreementAddress_RevertIf_InvalidAddress() public {
        vm.expectRevert("Invalid ServiceAgreement address");
        paymentManager.setServiceAgreementAddress(address(0));
    }
}
