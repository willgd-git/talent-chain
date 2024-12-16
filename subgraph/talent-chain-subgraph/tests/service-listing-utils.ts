import { newMockEvent } from "matchstick-as"
import { ethereum, BigInt, Address } from "@graphprotocol/graph-ts"
import {
  ServiceCreated,
  ServiceDeactivated,
  ServiceReactivated,
  ServiceUpdated,
  UserRegistrySet
} from "../generated/ServiceListing/ServiceListing"

export function createServiceCreatedEvent(
  serviceId: BigInt,
  provider: Address,
  price: BigInt,
  ipfsHash: string
): ServiceCreated {
  let serviceCreatedEvent = changetype<ServiceCreated>(newMockEvent())

  serviceCreatedEvent.parameters = new Array()

  serviceCreatedEvent.parameters.push(
    new ethereum.EventParam(
      "serviceId",
      ethereum.Value.fromUnsignedBigInt(serviceId)
    )
  )
  serviceCreatedEvent.parameters.push(
    new ethereum.EventParam("provider", ethereum.Value.fromAddress(provider))
  )
  serviceCreatedEvent.parameters.push(
    new ethereum.EventParam("price", ethereum.Value.fromUnsignedBigInt(price))
  )
  serviceCreatedEvent.parameters.push(
    new ethereum.EventParam("ipfsHash", ethereum.Value.fromString(ipfsHash))
  )

  return serviceCreatedEvent
}

export function createServiceDeactivatedEvent(
  serviceId: BigInt
): ServiceDeactivated {
  let serviceDeactivatedEvent = changetype<ServiceDeactivated>(newMockEvent())

  serviceDeactivatedEvent.parameters = new Array()

  serviceDeactivatedEvent.parameters.push(
    new ethereum.EventParam(
      "serviceId",
      ethereum.Value.fromUnsignedBigInt(serviceId)
    )
  )

  return serviceDeactivatedEvent
}

export function createServiceReactivatedEvent(
  serviceId: BigInt
): ServiceReactivated {
  let serviceReactivatedEvent = changetype<ServiceReactivated>(newMockEvent())

  serviceReactivatedEvent.parameters = new Array()

  serviceReactivatedEvent.parameters.push(
    new ethereum.EventParam(
      "serviceId",
      ethereum.Value.fromUnsignedBigInt(serviceId)
    )
  )

  return serviceReactivatedEvent
}

export function createServiceUpdatedEvent(
  serviceId: BigInt,
  newPrice: BigInt,
  newIpfsHash: string
): ServiceUpdated {
  let serviceUpdatedEvent = changetype<ServiceUpdated>(newMockEvent())

  serviceUpdatedEvent.parameters = new Array()

  serviceUpdatedEvent.parameters.push(
    new ethereum.EventParam(
      "serviceId",
      ethereum.Value.fromUnsignedBigInt(serviceId)
    )
  )
  serviceUpdatedEvent.parameters.push(
    new ethereum.EventParam(
      "newPrice",
      ethereum.Value.fromUnsignedBigInt(newPrice)
    )
  )
  serviceUpdatedEvent.parameters.push(
    new ethereum.EventParam(
      "newIpfsHash",
      ethereum.Value.fromString(newIpfsHash)
    )
  )

  return serviceUpdatedEvent
}

export function createUserRegistrySetEvent(
  userRegistryAddr: Address
): UserRegistrySet {
  let userRegistrySetEvent = changetype<UserRegistrySet>(newMockEvent())

  userRegistrySetEvent.parameters = new Array()

  userRegistrySetEvent.parameters.push(
    new ethereum.EventParam(
      "userRegistryAddr",
      ethereum.Value.fromAddress(userRegistryAddr)
    )
  )

  return userRegistrySetEvent
}
