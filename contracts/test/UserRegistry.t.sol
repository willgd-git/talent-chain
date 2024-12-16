// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {UserRegistry} from "../src/UserRegistry.sol";

/// @title UserRegistryBaseTest
/// @notice Base test contract for UserRegistry
abstract contract UserRegistryBaseTest is Test {
    event UserRegistered(address indexed userAddress, string ipfsHash);
    event UserProfileUpdated(address indexed userAddress, string oldIpfsHash, string newIpfsHash);

    UserRegistry public userRegistry;
    address owner = address(1);
    address user1 = address(2);
    address user2 = address(3);

    string constant ipfsHash1 = "QmUser1ProfileHash";
    string constant ipfsHash2 = "QmUser2ProfileHash";

    /// @notice Setup runs before each test method
    function setUp() public virtual {
        // Deploy the contract
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
        emit UserRegistered(user1, ipfsHash1);
        userRegistry.registerUser(ipfsHash1);

        string memory storedHash = userRegistry.userProfiles(user1);
        assertEq(storedHash, ipfsHash1, "User profile IPFS hash should match");
    }

    /// @notice Test revert if user already registered
    function test_RegisterUser_RevertIf_AlreadyRegistered() public {
        vm.prank(user1);
        userRegistry.registerUser(ipfsHash1);

        vm.prank(user1);
        vm.expectRevert("User already registered");
        userRegistry.registerUser(ipfsHash2);
    }

    /// @notice Test revert if IPFS hash is empty
    function test_RegisterUser_RevertIf_EmptyIpfsHash() public {
        vm.prank(user1);
        vm.expectRevert("IPFS hash cannot be empty");
        userRegistry.registerUser("");
    }
}

/// @title UserRegistryUpdateTest
/// @notice Tests the updateUserProfile function of UserRegistry
contract UserRegistryUpdateTest is UserRegistryBaseTest {

    /// @notice Test successful update of user profile
    function test_UpdateUserProfile_Success() public {
        vm.prank(user1);
        userRegistry.registerUser(ipfsHash1);

        string memory newIpfsHash = "QmUpdatedUser1ProfileHash";

        vm.prank(user1);
        vm.expectEmit(true, false, false, true);
        emit UserProfileUpdated(user1, ipfsHash1, newIpfsHash);
        userRegistry.updateUserProfile(newIpfsHash);

        string memory storedHash = userRegistry.userProfiles(user1);
        assertEq(storedHash, newIpfsHash, "User profile IPFS hash should be updated");
    }

    /// @notice Test revert if user is not registered
    function test_UpdateUserProfile_RevertIf_UserNotRegistered() public {
        string memory newIpfsHash = "QmUpdatedUser1ProfileHash";

        vm.prank(user1);
        vm.expectRevert("User not registered");
        userRegistry.updateUserProfile(newIpfsHash);
    }

    /// @notice Test revert if IPFS hash is empty
    function test_UpdateUserProfile_RevertIf_EmptyIpfsHash() public {
        vm.prank(user1);
        userRegistry.registerUser(ipfsHash1);

        vm.prank(user1);
        vm.expectRevert("IPFS hash cannot be empty");
        userRegistry.updateUserProfile("");
    }
}

/// @title UserRegistryCheckTest
/// @notice Tests the isUserRegistered function of UserRegistry
contract UserRegistryCheckTest is UserRegistryBaseTest {

    /// @notice Test checking an unregistered user
    function test_CheckRegistration_Unregistered() public view {
        bool registered = userRegistry.isUserRegistered(address(99));
        assertFalse(registered, "Unregistered address should return false");
    }

    /// @notice Test checking a registered user
    function test_CheckRegistration_Registered() public {
        vm.prank(user1);
        userRegistry.registerUser(ipfsHash1);

        bool registered = userRegistry.isUserRegistered(user1);
        assertTrue(registered, "Registered address should return true");
    }
}
