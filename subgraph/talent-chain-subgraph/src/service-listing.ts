import {
  ServiceCreated as ServiceCreatedEvent,
  ServiceDeactivated as ServiceDeactivatedEvent,
  ServiceReactivated as ServiceReactivatedEvent,
  ServiceUpdated as ServiceUpdatedEvent,
  UserRegistrySet as UserRegistrySetEvent,
} from "../generated/ServiceListing/ServiceListing"
import {
  ServiceCreated,
  ServiceDeactivated,
  ServiceReactivated,
  ServiceUpdated,
  UserRegistrySet,
} from "../generated/schema"

export function handleServiceCreated(event: ServiceCreatedEvent): void {
  let entity = new ServiceCreated(
    event.transaction.hash.concatI32(event.logIndex.toI32()),
  )
  entity.serviceId = event.params.serviceId
  entity.provider = event.params.provider
  entity.price = event.params.price

  entity.blockNumber = event.block.number
  entity.blockTimestamp = event.block.timestamp
  entity.transactionHash = event.transaction.hash

  entity.save()
}

export function handleServiceDeactivated(event: ServiceDeactivatedEvent): void {
  let entity = new ServiceDeactivated(
    event.transaction.hash.concatI32(event.logIndex.toI32()),
  )
  entity.serviceId = event.params.serviceId

  entity.blockNumber = event.block.number
  entity.blockTimestamp = event.block.timestamp
  entity.transactionHash = event.transaction.hash

  entity.save()
}

export function handleServiceReactivated(event: ServiceReactivatedEvent): void {
  let entity = new ServiceReactivated(
    event.transaction.hash.concatI32(event.logIndex.toI32()),
  )
  entity.serviceId = event.params.serviceId

  entity.blockNumber = event.block.number
  entity.blockTimestamp = event.block.timestamp
  entity.transactionHash = event.transaction.hash

  entity.save()
}

export function handleServiceUpdated(event: ServiceUpdatedEvent): void {
  let entity = new ServiceUpdated(
    event.transaction.hash.concatI32(event.logIndex.toI32()),
  )
  entity.serviceId = event.params.serviceId
  entity.newPrice = event.params.newPrice

  entity.blockNumber = event.block.number
  entity.blockTimestamp = event.block.timestamp
  entity.transactionHash = event.transaction.hash

  entity.save()
}

export function handleUserRegistrySet(event: UserRegistrySetEvent): void {
  let entity = new UserRegistrySet(
    event.transaction.hash.concatI32(event.logIndex.toI32()),
  )
  entity.userRegistryAddr = event.params.userRegistryAddr

  entity.blockNumber = event.block.number
  entity.blockTimestamp = event.block.timestamp
  entity.transactionHash = event.transaction.hash

  entity.save()
}
