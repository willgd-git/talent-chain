// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interfaces/IServiceAgreement.sol";

/// @title ReputationManager
/// @notice Manages provider reputation based on client or provider feedback once the agreement is either CompletedAccepted or DisputeResolved.
/// @dev Ratings are aggregated into a simple score. Uses IServiceAgreement for agreement info.
///      Ensures each agreement can only have one feedback submission.
contract ReputationManager {
    /// @notice The owner of the ReputationManager contract (could be the deployer)
    address public owner;

    /// @notice Reference to the ServiceAgreement contract
    IServiceAgreement public serviceAgreement;

    /// @notice Mapping from provider address to their cumulative score and total ratings
    mapping(address => uint256) public totalScore;
    mapping(address => uint256) public totalRatings;

    /// @notice Mapping to track if feedback has been submitted for a specific agreement
    mapping(uint256 => bool) public feedbackSubmitted;

    /// @notice Emitted when feedback is submitted
    /// @param agreementId The ID of the agreement
    /// @param reviewer The client or provider who submitted the feedback
    /// @param reviewee The provider receiving the feedback
    /// @param rating The rating given by the reviewer
    event FeedbackSubmitted(uint256 indexed agreementId, address indexed reviewer, address indexed reviewee, uint8 rating);

    /// @notice Emitted when the ServiceAgreement address is updated
    /// @param newServiceAgreement The address of the new ServiceAgreement contract
    event ServiceAgreementAddressSet(address indexed newServiceAgreement);

    /// @notice Constructor sets the initial owner
    constructor() {
        owner = msg.sender;
    }

    /// @notice Modifier to restrict functions to the contract owner
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner");
        _;
    }

    /// @notice Sets the ServiceAgreement contract address
    /// @dev Can only be called by the contract owner
    /// @param serviceAgreementAddr The address of the ServiceAgreement contract
    function setServiceAgreementAddress(address serviceAgreementAddr) external onlyOwner {
        require(serviceAgreementAddr != address(0), "Invalid ServiceAgreement address");
        serviceAgreement = IServiceAgreement(serviceAgreementAddr);
        emit ServiceAgreementAddressSet(serviceAgreementAddr);
    }

    /// @notice Submit feedback for the other party in an agreement
    /// @dev Agreement must be CompletedAccepted or DisputeResolved. Caller must be a participant (client or provider).
    ///      Each agreement can only have one feedback submission.
    /// @param agreementId The ID of the agreement
    /// @param rating A rating between 1 and 5
    function submitFeedback(uint256 agreementId, uint8 rating) external {
        require(rating >= 1 && rating <= 5, "Invalid rating");
        require(!feedbackSubmitted[agreementId], "Feedback already submitted for this agreement");

        (
            uint256 agreementIdOut,
            ,
            address client,
            address provider,
            ,
            IServiceAgreement.AgreementStatus status,
            
        ) = serviceAgreement.agreements(agreementId);

        require(agreementIdOut == agreementId, "Agreement not found");
        require(status == IServiceAgreement.AgreementStatus.CompletedAccepted || status == IServiceAgreement.AgreementStatus.DisputeResolved, "Agreement not in final feedback state");
        require(msg.sender == client, "Only client can submit feedback");

        // Update reputation
        totalRatings[provider] += 1;
        totalScore[provider] += rating;

        // Mark feedback as submitted for this agreement
        feedbackSubmitted[agreementId] = true;

        emit FeedbackSubmitted(agreementId, msg.sender, provider, rating);
    }

    /// @notice Get average rating of a user
    /// @param userAddress The user address
    /// @return avgRating The average rating (0 if no ratings)
    function getAverageRating(address userAddress) external view returns (uint256 avgRating) {
        if (totalRatings[userAddress] == 0) {
            return 0;
        }
        return totalScore[userAddress] / totalRatings[userAddress];
    }
}
