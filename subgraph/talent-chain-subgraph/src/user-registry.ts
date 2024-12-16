import {
  UserProfileUpdated as UserProfileUpdatedEvent,
  UserRegistered as UserRegisteredEvent
} from "../generated/UserRegistry/UserRegistry"
import { UserProfileUpdated, UserRegistered } from "../generated/schema"

export function handleUserProfileUpdated(event: UserProfileUpdatedEvent): void {
  let entity = new UserProfileUpdated(
    event.transaction.hash.concatI32(event.logIndex.toI32())
  )
  entity.userAddress = event.params.userAddress
  entity.oldIpfsHash = event.params.oldIpfsHash
  entity.newIpfsHash = event.params.newIpfsHash

  entity.blockNumber = event.block.number
  entity.blockTimestamp = event.block.timestamp
  entity.transactionHash = event.transaction.hash

  entity.save()
}

export function handleUserRegistered(event: UserRegisteredEvent): void {
  let entity = new UserRegistered(
    event.transaction.hash.concatI32(event.logIndex.toI32())
  )
  entity.userAddress = event.params.userAddress
  entity.ipfsHash = event.params.ipfsHash

  entity.blockNumber = event.block.number
  entity.blockTimestamp = event.block.timestamp
  entity.transactionHash = event.transaction.hash

  entity.save()
}
