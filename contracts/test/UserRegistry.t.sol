// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {UserRegistry} from "../src/UserRegistry.sol";

/// @title UserRegistryBaseTest
/// @notice Base test contract for UserRegistry, similar to VotingSystemBaseTest structure
abstract contract UserRegistryBaseTest is Test {
    event UserRegistered(address indexed userAddress);

    UserRegistry public userRegistry;
    address owner = address(1);
    address user1 = address(2);
    address user2 = address(3);

    /// @notice Setup runs before each test method
    function setUp() public virtual {
        // Deploy the contract as owner
        vm.prank(owner);
        userRegistry = new UserRegistry();
    }
}

/// @title UserRegistryRegisterTest
/// @notice Tests the registerUser function of UserRegistry
contract UserRegistryRegisterTest is UserRegistryBaseTest {

    /// @notice Test successful registration
    function test_RegisterUser() public {
        vm.prank(user1);

        vm.expectEmit(true, false, false, true);
        emit UserRegistered(user1);
        userRegistry.registerUser();

        bool registered = userRegistry.isUserRegistered(user1);
        assertTrue(registered, "User should be registered");
    }

    /// @notice Test revert if user already registered
    function test_RegisterUser_RevertIf_AlreadyRegistered() public {
        vm.startPrank(user1);
        userRegistry.registerUser();
        vm.expectRevert("User already registered");
        userRegistry.registerUser();
        vm.stopPrank();
    }
}

/// @title UserRegistryCheckTest
/// @notice Tests the checkRegistration function of UserRegistry
contract UserRegistryCheckTest is UserRegistryBaseTest {

    function test_CheckRegistration_Unregistered() public view {
        bool registered = userRegistry.isUserRegistered(address(99));
        assertFalse(registered, "Unregistered address should return false");
    }

    function test_CheckRegistration_Registered() public {
        // Register a user
        vm.prank(user1);
        userRegistry.registerUser();

        bool registered = userRegistry.isUserRegistered(user1);
        assertTrue(registered, "Registered address should return true");
    }
}