import { newMockEvent } from "matchstick-as"
import { ethereum, Address } from "@graphprotocol/graph-ts"
import { UserRegistered } from "../generated/UserRegistry/UserRegistry"

export function createUserRegisteredEvent(
  userAddress: Address
): UserRegistered {
  let userRegisteredEvent = changetype<UserRegistered>(newMockEvent())

  userRegisteredEvent.parameters = new Array()

  userRegisteredEvent.parameters.push(
    new ethereum.EventParam(
      "userAddress",
      ethereum.Value.fromAddress(userAddress)
    )
  )

  return userRegisteredEvent
}
