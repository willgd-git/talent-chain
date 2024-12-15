// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IPaymentManager.sol";

/// @title IServiceAgreement Interface
/// @notice Interface for reading and interacting with agreement data from the ServiceAgreement contract
interface IServiceAgreement {
    /// @notice Enumeration of possible agreement statuses
    enum AgreementStatus {
        Inactive,
        Proposed,
        Accepted,
        Paid,
        Completed,
        CompletedAccepted,
        Disputed,
        DisputeResolved,
        Cancelled
    }

    /// @notice Returns agreement details
    /// @param agreementId The ID of the agreement
    /// @return agreementIdOut The ID of the agreement
    /// @return serviceId The linked service ID
    /// @return client The client address
    /// @return provider The provider address
    /// @return amount The agreed amount
    /// @return status The current AgreementStatus
    /// @return completionTimestamp The timestamp when provider completed the service (if any)
    function agreements(uint256 agreementId) external view returns (
        uint256 agreementIdOut,
        uint256 serviceId,
        address client,
        address provider,
        uint256 amount,
        AgreementStatus status,
        uint256 completionTimestamp
    );

    /// @notice Marks the agreement as Paid.
    /// @dev Called by the PaymentManager contract after depositing exact amount.
    /// @param agreementId The ID of the agreement.
    function markAsPaid(uint256 agreementId) external;

    /// @notice Disputes the completed agreement.
    /// @dev Called by a participant (client or provider) if agreement is Completed.
    ///      Changes the state from Completed -> Disputed.
    /// @param agreementId The ID of the agreement.
    function disputeCompletedAgreement(uint256 agreementId) external;

    /// @notice Resolves the dispute by providing a final ruling.
    /// @dev Called by DisputeResolution contract or arbitrator to finalize the dispute.
    ///      Changes state from Disputed -> DisputeResolved and triggers distribution.
    /// @param agreementId The ID of the agreement.
    /// @param ruling The final ruling (ClientFavored, ProviderFavored, or Split).
    function resolveDispute(uint256 agreementId, IPaymentManager.Ruling ruling) external;
}
