import { newMockEvent } from "matchstick-as"
import { ethereum, BigInt, Address } from "@graphprotocol/graph-ts"
import {
  FeedbackSubmitted,
  ServiceAgreementAddressSet
} from "../generated/ReputationManager/ReputationManager"

export function createFeedbackSubmittedEvent(
  agreementId: BigInt,
  reviewer: Address,
  reviewee: Address,
  rating: i32
): FeedbackSubmitted {
  let feedbackSubmittedEvent = changetype<FeedbackSubmitted>(newMockEvent())

  feedbackSubmittedEvent.parameters = new Array()

  feedbackSubmittedEvent.parameters.push(
    new ethereum.EventParam(
      "agreementId",
      ethereum.Value.fromUnsignedBigInt(agreementId)
    )
  )
  feedbackSubmittedEvent.parameters.push(
    new ethereum.EventParam("reviewer", ethereum.Value.fromAddress(reviewer))
  )
  feedbackSubmittedEvent.parameters.push(
    new ethereum.EventParam("reviewee", ethereum.Value.fromAddress(reviewee))
  )
  feedbackSubmittedEvent.parameters.push(
    new ethereum.EventParam(
      "rating",
      ethereum.Value.fromUnsignedBigInt(BigInt.fromI32(rating))
    )
  )

  return feedbackSubmittedEvent
}

export function createServiceAgreementAddressSetEvent(
  newServiceAgreement: Address
): ServiceAgreementAddressSet {
  let serviceAgreementAddressSetEvent = changetype<ServiceAgreementAddressSet>(
    newMockEvent()
  )

  serviceAgreementAddressSetEvent.parameters = new Array()

  serviceAgreementAddressSetEvent.parameters.push(
    new ethereum.EventParam(
      "newServiceAgreement",
      ethereum.Value.fromAddress(newServiceAgreement)
    )
  )

  return serviceAgreementAddressSetEvent
}
