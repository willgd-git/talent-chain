import {
  FundsDeposited as FundsDepositedEvent,
  FundsDistributedAfterDispute as FundsDistributedAfterDisputeEvent,
  FundsRefunded as FundsRefundedEvent,
  FundsReleased as FundsReleasedEvent,
  ServiceAgreementAddressSet as ServiceAgreementAddressSetEvent,
} from "../generated/PaymentManager/PaymentManager"
import {
  FundsDeposited,
  FundsDistributedAfterDispute,
  FundsRefunded,
  FundsReleased,
  ServiceAgreementAddressSet,
} from "../generated/schema"

export function handleFundsDeposited(event: FundsDepositedEvent): void {
  let entity = new FundsDeposited(
    event.transaction.hash.concatI32(event.logIndex.toI32()),
  )
  entity.agreementId = event.params.agreementId
  entity.amount = event.params.amount

  entity.blockNumber = event.block.number
  entity.blockTimestamp = event.block.timestamp
  entity.transactionHash = event.transaction.hash

  entity.save()
}

export function handleFundsDistributedAfterDispute(
  event: FundsDistributedAfterDisputeEvent,
): void {
  let entity = new FundsDistributedAfterDispute(
    event.transaction.hash.concatI32(event.logIndex.toI32()),
  )
  entity.agreementId = event.params.agreementId
  entity.clientAmount = event.params.clientAmount
  entity.providerAmount = event.params.providerAmount

  entity.blockNumber = event.block.number
  entity.blockTimestamp = event.block.timestamp
  entity.transactionHash = event.transaction.hash

  entity.save()
}

export function handleFundsRefunded(event: FundsRefundedEvent): void {
  let entity = new FundsRefunded(
    event.transaction.hash.concatI32(event.logIndex.toI32()),
  )
  entity.agreementId = event.params.agreementId
  entity.amount = event.params.amount
  entity.to = event.params.to

  entity.blockNumber = event.block.number
  entity.blockTimestamp = event.block.timestamp
  entity.transactionHash = event.transaction.hash

  entity.save()
}

export function handleFundsReleased(event: FundsReleasedEvent): void {
  let entity = new FundsReleased(
    event.transaction.hash.concatI32(event.logIndex.toI32()),
  )
  entity.agreementId = event.params.agreementId
  entity.amount = event.params.amount
  entity.to = event.params.to

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
