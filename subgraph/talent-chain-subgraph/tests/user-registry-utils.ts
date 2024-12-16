import { newMockEvent } from "matchstick-as"
import { ethereum, Address } from "@graphprotocol/graph-ts"
import {
  UserProfileUpdated,
  UserRegistered
} from "../generated/UserRegistry/UserRegistry"

export function createUserProfileUpdatedEvent(
  userAddress: Address,
  oldIpfsHash: string,
  newIpfsHash: string
): UserProfileUpdated {
  let userProfileUpdatedEvent = changetype<UserProfileUpdated>(newMockEvent())

  userProfileUpdatedEvent.parameters = new Array()

  userProfileUpdatedEvent.parameters.push(
    new ethereum.EventParam(
      "userAddress",
      ethereum.Value.fromAddress(userAddress)
    )
  )
  userProfileUpdatedEvent.parameters.push(
    new ethereum.EventParam(
      "oldIpfsHash",
      ethereum.Value.fromString(oldIpfsHash)
    )
  )
  userProfileUpdatedEvent.parameters.push(
    new ethereum.EventParam(
      "newIpfsHash",
      ethereum.Value.fromString(newIpfsHash)
    )
  )

  return userProfileUpdatedEvent
}

export function createUserRegisteredEvent(
  userAddress: Address,
  ipfsHash: string
): UserRegistered {
  let userRegisteredEvent = changetype<UserRegistered>(newMockEvent())

  userRegisteredEvent.parameters = new Array()

  userRegisteredEvent.parameters.push(
    new ethereum.EventParam(
      "userAddress",
      ethereum.Value.fromAddress(userAddress)
    )
  )
  userRegisteredEvent.parameters.push(
    new ethereum.EventParam("ipfsHash", ethereum.Value.fromString(ipfsHash))
  )

  return userRegisteredEvent
}
