// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {UserRegistry} from "../src/UserRegistry.sol";
import {ServiceListing} from "../src/ServiceListing.sol";
import {IUserRegistry} from "../src/interfaces/IUserRegistry.sol";

/// @title ServiceListingBaseTest
/// @notice Base test contract for ServiceListing, sets up UserRegistry and ServiceListing
/// @dev Provides helper functions for creating services and managing users
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
        vm.startPrank(owner);
        userRegistry = new UserRegistry();
        serviceListing = new ServiceListing();
        // Now we must set the userRegistry after deployment
        serviceListing.setUserRegistry(address(userRegistry));
        vm.stopPrank();

        // Register provider1
        vm.prank(provider1);
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

    /// @notice Test successful service creation
    function test_CreateService_Success() public {
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

    /// @notice Test service creation revert if provider is not registered
    function test_CreateService_RevertIf_ProviderNotRegistered() public {
        // provider2 not registered yet
        vm.prank(provider2);
        vm.expectRevert("Provider not registered");
        serviceListing.createService(100);
    }

    /// @notice Test service creation revert if price is zero
    function test_CreateService_RevertIf_PriceZero() public {
        vm.prank(provider1);
        vm.expectRevert("Price must be greater than zero");
        serviceListing.createService(0);
    }
}

/// @title ServiceListingUpdateTest
/// @notice Tests the updateService function of ServiceListing
contract ServiceListingUpdateTest is ServiceListingBaseTest {
    uint256 serviceId;

    /// @notice Setup runs before each test method
    function setUp() public override {
        super.setUp();
        serviceId = createService(provider1, 100);
    }

    /// @notice Test successful service update
    function test_UpdateService_Success() public {
        vm.startPrank(provider1);
        vm.expectEmit(true, false, false, true);
        emit ServiceUpdated(serviceId, 200);
        serviceListing.updateService(serviceId, 200);
        vm.stopPrank();

        (, , uint256 newPrice,) = serviceListing.services(serviceId);
        assertEq(newPrice, 200, "Price should be updated");
    }

    /// @notice Test service update revert if not called by provider
    function test_UpdateService_RevertIf_NotProvider() public {
        vm.startPrank(nonProvider);
        vm.expectRevert("Only provider can modify");
        serviceListing.updateService(serviceId, 200);
        vm.stopPrank();
    }

    /// @notice Test service update revert if service is inactive
    function test_UpdateService_RevertIf_Inactive() public {
        // Deactivate first
        vm.prank(provider1);
        serviceListing.deactivateService(serviceId);

        vm.startPrank(provider1);
        vm.expectRevert("Service not active");
        serviceListing.updateService(serviceId, 200);
        vm.stopPrank();
    }

    /// @notice Test service update revert if new price is zero
    function test_UpdateService_RevertIf_PriceZero() public {
        vm.startPrank(provider1);
        vm.expectRevert("Price must be greater than zero");
        serviceListing.updateService(serviceId, 0);
        vm.stopPrank();
    }
}

/// @title ServiceListingDeactivateTest
/// @notice Tests the deactivateService function of ServiceListing
contract ServiceListingDeactivateTest is ServiceListingBaseTest {
    uint256 serviceId;

    /// @notice Setup runs before each test method
    function setUp() public override {
        super.setUp();
        serviceId = createService(provider1, 100);
    }

    /// @notice Test successful service deactivation
    function test_DeactivateService_Success() public {
        vm.startPrank(provider1);
        vm.expectEmit(true, false, false, true);
        emit ServiceDeactivated(serviceId);
        serviceListing.deactivateService(serviceId);
        vm.stopPrank();

        ( , , , bool isActive) = serviceListing.services(serviceId);
        assertFalse(isActive, "Service should be inactive");
    }

    /// @notice Test service deactivation revert if not called by provider
    function test_DeactivateService_RevertIf_NotProvider() public {
        vm.startPrank(nonProvider);
        vm.expectRevert("Only provider can modify");
        serviceListing.deactivateService(serviceId);
        vm.stopPrank();
    }

    /// @notice Test service deactivation revert if already inactive
    function test_DeactivateService_RevertIf_AlreadyInactive() public {
        vm.prank(provider1);
        serviceListing.deactivateService(serviceId);

        vm.startPrank(provider1);
        vm.expectRevert("Already inactive");
        serviceListing.deactivateService(serviceId);
        vm.stopPrank();
    }
}

/// @title ServiceListingReactivateTest
/// @notice Tests the reactivateService function of ServiceListing
contract ServiceListingReactivateTest is ServiceListingBaseTest {
    uint256 serviceId;

    /// @notice Setup runs before each test method
    function setUp() public override {
        super.setUp();
        serviceId = createService(provider1, 100);
        // Deactivate the service first
        vm.prank(provider1);
        serviceListing.deactivateService(serviceId);
    }

    /// @notice Test successful service reactivation
    function test_ReactivateService_Success() public {
        vm.startPrank(provider1);
        vm.expectEmit(true, false, false, true);
        emit ServiceReactivated(serviceId);
        serviceListing.reactivateService(serviceId);
        vm.stopPrank();

        ( , , , bool isActive) = serviceListing.services(serviceId);
        assertTrue(isActive, "Service should be active again");
    }

    /// @notice Test service reactivation revert if not called by provider
    function test_ReactivateService_RevertIf_NotProvider() public {
        vm.startPrank(nonProvider);
        vm.expectRevert("Only provider can modify");
        serviceListing.reactivateService(serviceId);
        vm.stopPrank();
    }

    /// @notice Test service reactivation revert if already active
    function test_ReactivateService_RevertIf_AlreadyActive() public {
        vm.prank(provider1);
        serviceListing.reactivateService(serviceId); // now active

        vm.startPrank(provider1);
        vm.expectRevert("Service already active");
        serviceListing.reactivateService(serviceId);
        vm.stopPrank();
    }
}

/// @title ServiceListingSetUserRegistryTest
/// @notice Tests the setUserRegistry function of ServiceListing
contract ServiceListingSetUserRegistryTest is Test {
    event UserRegistrySet(address userRegistryAddr);
    event ServiceCreated(uint256 indexed serviceId, address indexed provider, uint256 price);

    ServiceListing public serviceListing;
    UserRegistry public newUserRegistry;

    address owner = address(1);
    address newOwner = address(5);
    address provider1 = address(2);
    address provider2 = address(3);
    address nonOwner = address(4);

    /// @notice Setup runs before each test method
    function setUp() public {
        vm.startPrank(owner);
        serviceListing = new ServiceListing();
        vm.stopPrank();
    }

    /// @notice Test successful setting of UserRegistry by owner
    function test_SetUserRegistry_Success() public {
        newUserRegistry = new UserRegistry();

        vm.startPrank(owner);
        vm.expectEmit(true, false, false, false);
        emit UserRegistrySet(address(newUserRegistry));
        serviceListing.setUserRegistry(address(newUserRegistry));
        vm.stopPrank();

        assertEq(address(serviceListing.userRegistry()), address(newUserRegistry), "UserRegistry should be set correctly");
    }

    /// @notice Test setting UserRegistry revert if called by non-owner
    function test_SetUserRegistry_RevertIf_NotOwner() public {
        newUserRegistry = new UserRegistry();

        vm.startPrank(nonOwner);
        vm.expectRevert("Only owner");
        serviceListing.setUserRegistry(address(newUserRegistry));
        vm.stopPrank();

        assertEq(address(serviceListing.userRegistry()), address(0), "UserRegistry should not be set");
    }

    /// @notice Test setting UserRegistry revert if address is zero
    function test_SetUserRegistry_RevertIf_InvalidAddress() public {
        vm.startPrank(owner);
        vm.expectRevert("Invalid UserRegistry address");
        serviceListing.setUserRegistry(address(0));
        vm.stopPrank();

        assertEq(address(serviceListing.userRegistry()), address(0), "UserRegistry should not be set");
    }

    /// @notice Test owner can update UserRegistry to a new address
    function test_SetUserRegistry_UpdateSuccessfully() public {
        newUserRegistry = new UserRegistry();

        vm.startPrank(owner);
        serviceListing.setUserRegistry(address(newUserRegistry));
        vm.stopPrank();

        assertEq(address(serviceListing.userRegistry()), address(newUserRegistry), "UserRegistry should be set correctly");

        // Deploy another UserRegistry
        UserRegistry anotherUserRegistry = new UserRegistry();

        vm.startPrank(owner);
        serviceListing.setUserRegistry(address(anotherUserRegistry));
        vm.stopPrank();

        assertEq(address(serviceListing.userRegistry()), address(anotherUserRegistry), "UserRegistry should be updated correctly");
    }

    /// @notice Test that after setting UserRegistry, registeredProvider modifier works correctly
    function test_SetUserRegistry_AfterSetting_UserProviderModifier() public {
        newUserRegistry = new UserRegistry();

        // Set new UserRegistry
        vm.startPrank(owner);
        serviceListing.setUserRegistry(address(newUserRegistry));
        vm.stopPrank();

        // Register provider1 in new UserRegistry
        vm.prank(provider1);
        newUserRegistry.registerUser();

        // Attempt to create service with provider1
        vm.prank(provider1);
        vm.expectEmit(true, true, false, true);
        emit ServiceCreated(1, provider1, 100);
        uint256 serviceId = serviceListing.createService(100);

        ( , address prov, uint256 price, bool isActive) = serviceListing.services(serviceId);
        assertEq(prov, provider1, "Provider should match");
        assertEq(price, 100, "Price should match");
        assertTrue(isActive, "Service should be active");
    }
}
