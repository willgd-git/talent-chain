// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title IPaymentManager Interface
/// @notice Defines the external functions for the PaymentManager contract that other contracts can interact with.
/// @dev Includes functions for releasing funds, handling disputes, and refunds.
interface IPaymentManager {
    /// @notice Enumeration of possible dispute rulings
    enum Ruling { None, ClientFavored, ProviderFavored, Split }

    /// @notice Releases funds to the provider after the agreement is CompletedAccepted.
    /// @param agreementId The ID of the agreement.
    function releaseFunds(uint256 agreementId) external;

    /// @notice Distributes funds based on the final dispute ruling.
    /// @param agreementId The ID of the agreement.
    /// @param ruling The outcome of the dispute.
    function distributeAfterDispute(uint256 agreementId, Ruling ruling) external;

    /// @notice Deposits funds into the escrow for a specific agreement.
    /// @dev Typically called by the ServiceAgreement contract when marking an agreement as paid.
    /// @param agreementId The ID of the agreement.
    function depositFunds(uint256 agreementId) external payable;
}
