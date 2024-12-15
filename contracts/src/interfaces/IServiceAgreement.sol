// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title IServiceAgreement Interface
/// @notice Interface for reading agreement data from ServiceAgreement contract
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
    /// @dev Can only be called by the PaymentManager contract.
    /// @param agreementId The ID of the agreement.
    function markAsPaid(uint256 agreementId) external;
}
