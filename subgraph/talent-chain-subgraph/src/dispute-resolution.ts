import {
  ArbitratorSet as ArbitratorSetEvent,
  ServiceAgreementAddressSet as ServiceAgreementAddressSetEvent,
} from "../generated/DisputeResolution/DisputeResolution"
import { ArbitratorSet, ServiceAgreementAddressSet } from "../generated/schema"

export function handleArbitratorSet(event: ArbitratorSetEvent): void {
  let entity = new ArbitratorSet(
    event.transaction.hash.concatI32(event.logIndex.toI32()),
  )
  entity.newArbitrator = event.params.newArbitrator

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
