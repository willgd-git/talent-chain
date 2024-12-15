// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

// Import Foundry's Script utilities
import "forge-std/Script.sol";

// Import your contracts
import "../src/UserRegistry.sol";
import "../src/ServiceListing.sol";
import "../src/ServiceAgreement.sol";
import "../src/PaymentManager.sol";
import "../src/DisputeResolution.sol";
import "../src/ReputationManager.sol";

/// @title DeployContracts
/// @notice Deploys and connects UserRegistry, ServiceListing, ServiceAgreement, PaymentManager, DisputeResolution, and ReputationManager contracts.
/// @dev Uses the deploying wallet's private key to derive the deployer's address for role assignments.
contract DeployContracts is Script {
    // Define the deploying account's private key via environment variable
    uint256 privateKey = vm.envUint("PRIVATE_KEY");

    // Derive the deployer's address from the private key
    address deployer = vm.addr(privateKey);

    function run() external {
        // Start broadcasting transactions using the deployer's PRIVATE_KEY
        vm.startBroadcast(privateKey);

        // 1. Deploy UserRegistry
        UserRegistry userRegistry = new UserRegistry();
        console.log("UserRegistry deployed at:", address(userRegistry));

        // 2. Deploy ServiceListing
        ServiceListing serviceListing = new ServiceListing();
        console.log("ServiceListing deployed at:", address(serviceListing));

        // 3. Set UserRegistry address in ServiceListing
        serviceListing.setUserRegistry(address(userRegistry));
        console.log("ServiceListing linked to UserRegistry");

        // 4. Deploy PaymentManager
        PaymentManager paymentManager = new PaymentManager();
        console.log("PaymentManager deployed at:", address(paymentManager));

        // 5. Deploy ServiceAgreement
        ServiceAgreement serviceAgreement = new ServiceAgreement();
        console.log("ServiceAgreement deployed at:", address(serviceAgreement));

        // 6. Set ServiceListing and PaymentManager addresses in ServiceAgreement
        serviceAgreement.setServiceListingAddress(address(serviceListing));
        serviceAgreement.setPaymentManagerAddress(address(paymentManager));
        console.log("ServiceAgreement linked to ServiceListing and PaymentManager");

        // 7. Set ServiceAgreement address in PaymentManager
        paymentManager.setServiceAgreementAddress(address(serviceAgreement));
        console.log("PaymentManager linked to ServiceAgreement");

        // 8. Deploy DisputeResolution
        DisputeResolution disputeResolution = new DisputeResolution();
        console.log("DisputeResolution deployed at:", address(disputeResolution));

        // 9. Set ServiceAgreement address in DisputeResolution
        disputeResolution.setServiceAgreementAddress(address(serviceAgreement));
        console.log("DisputeResolution linked to ServiceAgreement");

        // 10. Set the deployer as the arbitrator in DisputeResolution
        disputeResolution.setArbitrator(deployer); // Using the derived address
        console.log("Arbitrator set in DisputeResolution as:", deployer);

        // 11. Deploy ReputationManager
        ReputationManager reputationManager = new ReputationManager();
        console.log("ReputationManager deployed at:", address(reputationManager));

        // 12. Set ServiceAgreement address in ReputationManager
        reputationManager.setServiceAgreementAddress(address(serviceAgreement));
        console.log("ReputationManager linked to ServiceAgreement");

        // End broadcasting
        vm.stopBroadcast();
    }
}
