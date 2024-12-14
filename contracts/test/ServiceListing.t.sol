// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {UserRegistry} from "../src/UserRegistry.sol";
import {ServiceListing} from "../src/ServiceListing.sol";
import {IUserRegistry} from "../src/interfaces/IUserRegistry.sol";

/// @title ServiceListingBaseTest
/// @notice Base test contract for ServiceListing, sets up UserRegistry and ServiceListing
abstract contract ServiceListingBaseTest is Test {
    event ServiceCreated(uint256 indexed serviceId, address indexed provider, uint256 price);
    event ServiceUpdated(uint256 indexed serviceId, uint256 newPrice);
    event ServiceDeactivated(uint256 indexed serviceId);
    event ServiceReactivated(uint256 indexed serviceId);

    UserRegistry public userRegistry;
    ServiceListing public serviceListing;

    address owner = address(1);
    address provider1 = address(2);
    address provider2 = address(3);
    address nonProvider = address(4);

    /// @notice Setup runs before each test method
    function setUp() public virtual {
        // Deploy UserRegistry as owner
        vm.startPrank(owner);
        userRegistry = new UserRegistry();
        vm.stopPrank();

        // Deploy ServiceListing with reference to UserRegistry
        vm.prank(owner);
        serviceListing = new ServiceListing(address(userRegistry));
    }

    /// @notice Helper function: register a user in UserRegistry
    /// @param user The user address to register
    function registerUser(address user) internal {
        vm.prank(user);
        userRegistry.registerUser();
    }

    /// @notice Helper function: create a service from a registered provider
    /// @param provider The provider who creates the service
    /// @param price The price of the service
    /// @return serviceId The ID of the created service
    function createService(address provider, uint256 price) internal returns (uint256 serviceId) {
        vm.prank(provider);
        serviceId = serviceListing.createService(price);
    }
}

/// @title ServiceListingCreateTest
/// @notice Tests the createService function of ServiceListing
contract ServiceListingCreateTest is ServiceListingBaseTest {

    function test_CreateService_Success() public {
        registerUser(provider1);

        vm.startPrank(provider1);
        vm.expectEmit(true, true, false, true);
        emit ServiceCreated(1, provider1, 100);
        uint256 serviceId = serviceListing.createService(100);
        vm.stopPrank();

        ( , address prov, uint256 price, bool isActive) = serviceListing.services(serviceId);
        assertEq(prov, provider1, "Provider should match");
        assertEq(price, 100, "Price should match");
        assertTrue(isActive, "Service should be active");
    }

    function test_CreateService_RevertIf_ProviderNotRegistered() public {
        vm.startPrank(provider1);
        vm.expectRevert("Provider not registered");
        serviceListing.createService(100);
        vm.stopPrank();
    }

    function test_CreateService_RevertIf_PriceZero() public {
        registerUser(provider1);

        vm.startPrank(provider1);
        vm.expectRevert("Price must be greater than zero");
        serviceListing.createService(0);
        vm.stopPrank();
    }
}

/// @title ServiceListingUpdateTest
/// @notice Tests the updateService function of ServiceListing
contract ServiceListingUpdateTest is ServiceListingBaseTest {

    uint256 serviceId;

    function setUp() public override {
        super.setUp();
        registerUser(provider1);
        serviceId = createService(provider1, 100);
    }

    function test_UpdateService_Success() public {
        vm.startPrank(provider1);
        vm.expectEmit(true, false, false, true);
        emit ServiceUpdated(serviceId, 200);
        serviceListing.updateService(serviceId, 200);
        vm.stopPrank();

        (, , uint256 newPrice,) = serviceListing.services(serviceId);
        assertEq(newPrice, 200, "Price should be updated");
    }

    function test_UpdateService_RevertIf_NotProvider() public {
        vm.startPrank(nonProvider);
        vm.expectRevert("Only provider can modify");
        serviceListing.updateService(serviceId, 200);
        vm.stopPrank();
    }

    function test_UpdateService_RevertIf_Inactive() public {
        // Deactivate first
        vm.prank(provider1);
        serviceListing.deactivateService(serviceId);

        vm.startPrank(provider1);
        vm.expectRevert("Service not active");
        serviceListing.updateService(serviceId, 200);
        vm.stopPrank();
    }

    function test_UpdateService_RevertIf_PriceZero() public {
        vm.startPrank(provider1);
        vm.expectRevert("Price must be greater than zero");
        serviceListing.updateService(serviceId, 0);
        vm.stopPrank();
    }
}

/// @title ServiceListingDeactivateTest
/// @notice Tests the deactivateService function
contract ServiceListingDeactivateTest is ServiceListingBaseTest {

    uint256 serviceId;

    function setUp() public override {
        super.setUp();
        registerUser(provider1);
        serviceId = createService(provider1, 100);
    }

    function test_DeactivateService_Success() public {
        vm.startPrank(provider1);
        vm.expectEmit(true, false, false, true);
        emit ServiceDeactivated(serviceId);
        serviceListing.deactivateService(serviceId);
        vm.stopPrank();

        ( , , , bool isActive) = serviceListing.services(serviceId);
        assertFalse(isActive, "Service should be inactive");
    }

    function test_DeactivateService_RevertIf_NotProvider() public {
        vm.startPrank(nonProvider);
        vm.expectRevert("Only provider can modify");
        serviceListing.deactivateService(serviceId);
        vm.stopPrank();
    }

    function test_DeactivateService_RevertIf_AlreadyInactive() public {
        vm.startPrank(provider1);
        serviceListing.deactivateService(serviceId);
        vm.expectRevert("Already inactive");
        serviceListing.deactivateService(serviceId);
        vm.stopPrank();
    }
}

/// @title ServiceListingReactivateTest
/// @notice Tests the reactivateService function
contract ServiceListingReactivateTest is ServiceListingBaseTest {

    uint256 serviceId;

    function setUp() public override {
        super.setUp();
        registerUser(provider1);
        serviceId = createService(provider1, 100);
        // Deactivate the service first
        vm.prank(provider1);
        serviceListing.deactivateService(serviceId);
    }

    function test_ReactivateService_Success() public {
        vm.startPrank(provider1);
        vm.expectEmit(true, false, false, true);
        emit ServiceReactivated(serviceId);
        serviceListing.reactivateService(serviceId);
        vm.stopPrank();

        ( , , , bool isActive) = serviceListing.services(serviceId);
        assertTrue(isActive, "Service should be active again");
    }

    function test_ReactivateService_RevertIf_NotProvider() public {
        vm.startPrank(nonProvider);
        vm.expectRevert("Only provider can modify");
        serviceListing.reactivateService(serviceId);
        vm.stopPrank();
    }

    function test_ReactivateService_RevertIf_AlreadyActive() public {
        vm.prank(provider1);
        serviceListing.reactivateService(serviceId); // now active

        vm.startPrank(provider1);
        vm.expectRevert("Service already active");
        serviceListing.reactivateService(serviceId);
        vm.stopPrank();
    }
}
