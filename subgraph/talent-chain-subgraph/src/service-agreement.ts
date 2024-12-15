import {
  AgreementAcceptedByProvider as AgreementAcceptedByProviderEvent,
  AgreementAmountUpdated as AgreementAmountUpdatedEvent,
  AgreementCancelled as AgreementCancelledEvent,
  AgreementCompleted as AgreementCompletedEvent,
  AgreementCompletedAccepted as AgreementCompletedAcceptedEvent,
  AgreementCreated as AgreementCreatedEvent,
  AgreementDisputeResolved as AgreementDisputeResolvedEvent,
  AgreementDisputed as AgreementDisputedEvent,
  AgreementPaid as AgreementPaidEvent,
  PaymentManagerAddressSet as PaymentManagerAddressSetEvent,
  ServiceListingAddressSet as ServiceListingAddressSetEvent,
} from "../generated/ServiceAgreement/ServiceAgreement"
import {
  AgreementAcceptedByProvider,
  AgreementAmountUpdated,
  AgreementCancelled,
  AgreementCompleted,
  AgreementCompletedAccepted,
  AgreementCreated,
  AgreementDisputeResolved,
  AgreementDisputed,
  AgreementPaid,
  PaymentManagerAddressSet,
  ServiceListingAddressSet,
} from "../generated/schema"

export function handleAgreementAcceptedByProvider(
  event: AgreementAcceptedByProviderEvent,
): void {
  let entity = new AgreementAcceptedByProvider(
    event.transaction.hash.concatI32(event.logIndex.toI32()),
  )
  entity.agreementId = event.params.agreementId

  entity.blockNumber = event.block.number
  entity.blockTimestamp = event.block.timestamp
  entity.transactionHash = event.transaction.hash

  entity.save()
}

export function handleAgreementAmountUpdated(
  event: AgreementAmountUpdatedEvent,
): void {
  let entity = new AgreementAmountUpdated(
    event.transaction.hash.concatI32(event.logIndex.toI32()),
  )
  entity.agreementId = event.params.agreementId
  entity.oldAmount = event.params.oldAmount
  entity.newAmount = event.params.newAmount

  entity.blockNumber = event.block.number
  entity.blockTimestamp = event.block.timestamp
  entity.transactionHash = event.transaction.hash

  entity.save()
}

export function handleAgreementCancelled(event: AgreementCancelledEvent): void {
  let entity = new AgreementCancelled(
    event.transaction.hash.concatI32(event.logIndex.toI32()),
  )
  entity.agreementId = event.params.agreementId

  entity.blockNumber = event.block.number
  entity.blockTimestamp = event.block.timestamp
  entity.transactionHash = event.transaction.hash

  entity.save()
}

export function handleAgreementCompleted(event: AgreementCompletedEvent): void {
  let entity = new AgreementCompleted(
    event.transaction.hash.concatI32(event.logIndex.toI32()),
  )
  entity.agreementId = event.params.agreementId

  entity.blockNumber = event.block.number
  entity.blockTimestamp = event.block.timestamp
  entity.transactionHash = event.transaction.hash

  entity.save()
}

export function handleAgreementCompletedAccepted(
  event: AgreementCompletedAcceptedEvent,
): void {
  let entity = new AgreementCompletedAccepted(
    event.transaction.hash.concatI32(event.logIndex.toI32()),
  )
  entity.agreementId = event.params.agreementId

  entity.blockNumber = event.block.number
  entity.blockTimestamp = event.block.timestamp
  entity.transactionHash = event.transaction.hash

  entity.save()
}

export function handleAgreementCreated(event: AgreementCreatedEvent): void {
  let entity = new AgreementCreated(
    event.transaction.hash.concatI32(event.logIndex.toI32()),
  )
  entity.agreementId = event.params.agreementId
  entity.serviceId = event.params.serviceId
  entity.client = event.params.client
  entity.provider = event.params.provider
  entity.amount = event.params.amount

  entity.blockNumber = event.block.number
  entity.blockTimestamp = event.block.timestamp
  entity.transactionHash = event.transaction.hash

  entity.save()
}

export function handleAgreementDisputeResolved(
  event: AgreementDisputeResolvedEvent,
): void {
  let entity = new AgreementDisputeResolved(
    event.transaction.hash.concatI32(event.logIndex.toI32()),
  )
  entity.agreementId = event.params.agreementId
  entity.ruling = event.params.ruling

  entity.blockNumber = event.block.number
  entity.blockTimestamp = event.block.timestamp
  entity.transactionHash = event.transaction.hash

  entity.save()
}

export function handleAgreementDisputed(event: AgreementDisputedEvent): void {
  let entity = new AgreementDisputed(
    event.transaction.hash.concatI32(event.logIndex.toI32()),
  )
  entity.agreementId = event.params.agreementId

  entity.blockNumber = event.block.number
  entity.blockTimestamp = event.block.timestamp
  entity.transactionHash = event.transaction.hash

  entity.save()
}

export function handleAgreementPaid(event: AgreementPaidEvent): void {
  let entity = new AgreementPaid(
    event.transaction.hash.concatI32(event.logIndex.toI32()),
  )
  entity.agreementId = event.params.agreementId

  entity.blockNumber = event.block.number
  entity.blockTimestamp = event.block.timestamp
  entity.transactionHash = event.transaction.hash

  entity.save()
}

export function handlePaymentManagerAddressSet(
  event: PaymentManagerAddressSetEvent,
): void {
  let entity = new PaymentManagerAddressSet(
    event.transaction.hash.concatI32(event.logIndex.toI32()),
  )
  entity.newPaymentManager = event.params.newPaymentManager

  entity.blockNumber = event.block.number
  entity.blockTimestamp = event.block.timestamp
  entity.transactionHash = event.transaction.hash

  entity.save()
}

export function handleServiceListingAddressSet(
  event: ServiceListingAddressSetEvent,
): void {
  let entity = new ServiceListingAddressSet(
    event.transaction.hash.concatI32(event.logIndex.toI32()),
  )
  entity.newServiceListing = event.params.newServiceListing

  entity.blockNumber = event.block.number
  entity.blockTimestamp = event.block.timestamp
  entity.transactionHash = event.transaction.hash

  entity.save()
}
