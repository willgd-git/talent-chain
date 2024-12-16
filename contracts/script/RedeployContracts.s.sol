// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import "../src/UserRegistry.sol";
import "../src/ServiceListing.sol";
import "../src/ServiceAgreement.sol";

/// @title RedeployContractsScript
/// @notice Script to redeploy UserRegistry and ServiceListing contracts, and reset ServiceListing address in ServiceAgreement
contract RedeployContractsScript is Script {
    function run() external {
        // Load environment variables
        uint256 privateKey = vm.envUint("PRIVATE_KEY");
        address serviceAgreementAddress = address(0x0061503DCb9a2eEb4bD56125C6807130Eb215c1a);

        // Start broadcasting transactions
        vm.startBroadcast(privateKey);

        // 1. Deploy the UserRegistry contract
        UserRegistry userRegistry = new UserRegistry();
        console.log("UserRegistry deployed at:", address(userRegistry));

        // 2. Deploy the ServiceListing contract
        ServiceListing serviceListing = new ServiceListing();
        console.log("ServiceListing deployed at:", address(serviceListing));

        // 3. Set the UserRegistry address in the ServiceListing contract
        serviceListing.setUserRegistry(address(userRegistry));
        console.log("UserRegistry address set in ServiceListing");

        // 4. Reset the ServiceListing address in the ServiceAgreement contract
        ServiceAgreement serviceAgreement = ServiceAgreement(serviceAgreementAddress);
        serviceAgreement.setServiceListingAddress(address(serviceListing));
        console.log("ServiceListing address reset in ServiceAgreement");

        // Stop broadcasting transactions
        vm.stopBroadcast();
    }
}
