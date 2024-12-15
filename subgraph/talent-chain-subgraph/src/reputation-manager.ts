import {
  FeedbackSubmitted as FeedbackSubmittedEvent,
  ServiceAgreementAddressSet as ServiceAgreementAddressSetEvent,
} from "../generated/ReputationManager/ReputationManager"
import {
  FeedbackSubmitted,
  ServiceAgreementAddressSet,
} from "../generated/schema"

export function handleFeedbackSubmitted(event: FeedbackSubmittedEvent): void {
  let entity = new FeedbackSubmitted(
    event.transaction.hash.concatI32(event.logIndex.toI32()),
  )
  entity.agreementId = event.params.agreementId
  entity.reviewer = event.params.reviewer
  entity.reviewee = event.params.reviewee
  entity.rating = event.params.rating

  entity.blockNumber = event.block.number
  entity.blockTimestamp = event.block.timestamp
  entity.transactionHash = event.transaction.hash

  entity.save()
}

export function handleServiceAgreementAddressSet(
  event: ServiceAgreementAddressSetEvent,
): void {
  let entity = new ServiceAgreementAddressSet(
    event.transaction.hash.concatI32(event.logIndex.toI32()),
  )
  entity.newServiceAgreement = event.params.newServiceAgreement

  entity.blockNumber = event.block.number
  entity.blockTimestamp = event.block.timestamp
  entity.transactionHash = event.transaction.hash

  entity.save()
}
