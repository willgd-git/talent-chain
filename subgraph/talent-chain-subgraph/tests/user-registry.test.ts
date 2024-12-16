import {
  assert,
  describe,
  test,
  clearStore,
  beforeAll,
  afterAll
} from "matchstick-as/assembly/index"
import { Address } from "@graphprotocol/graph-ts"
import { UserProfileUpdated } from "../generated/schema"
import { UserProfileUpdated as UserProfileUpdatedEvent } from "../generated/UserRegistry/UserRegistry"
import { handleUserProfileUpdated } from "../src/user-registry"
import { createUserProfileUpdatedEvent } from "./user-registry-utils"

// Tests structure (matchstick-as >=0.5.0)
// https://thegraph.com/docs/en/developer/matchstick/#tests-structure-0-5-0

describe("Describe entity assertions", () => {
  beforeAll(() => {
    let userAddress = Address.fromString(
      "0x0000000000000000000000000000000000000001"
    )
    let oldIpfsHash = "Example string value"
    let newIpfsHash = "Example string value"
    let newUserProfileUpdatedEvent = createUserProfileUpdatedEvent(
      userAddress,
      oldIpfsHash,
      newIpfsHash
    )
    handleUserProfileUpdated(newUserProfileUpdatedEvent)
  })

  afterAll(() => {
    clearStore()
  })

  // For more test scenarios, see:
  // https://thegraph.com/docs/en/developer/matchstick/#write-a-unit-test

  test("UserProfileUpdated created and stored", () => {
    assert.entityCount("UserProfileUpdated", 1)

    // 0xa16081f360e3847006db660bae1c6d1b2e17ec2a is the default address used in newMockEvent() function
    assert.fieldEquals(
      "UserProfileUpdated",
      "0xa16081f360e3847006db660bae1c6d1b2e17ec2a-1",
      "userAddress",
      "0x0000000000000000000000000000000000000001"
    )
    assert.fieldEquals(
      "UserProfileUpdated",
      "0xa16081f360e3847006db660bae1c6d1b2e17ec2a-1",
      "oldIpfsHash",
      "Example string value"
    )
    assert.fieldEquals(
      "UserProfileUpdated",
      "0xa16081f360e3847006db660bae1c6d1b2e17ec2a-1",
      "newIpfsHash",
      "Example string value"
    )

    // More assert options:
    // https://thegraph.com/docs/en/developer/matchstick/#asserts
  })
})
