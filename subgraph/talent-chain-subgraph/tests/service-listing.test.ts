import {
  assert,
  describe,
  test,
  clearStore,
  beforeAll,
  afterAll
} from "matchstick-as/assembly/index"
import { BigInt, Address } from "@graphprotocol/graph-ts"
import { ServiceCreated } from "../generated/schema"
import { ServiceCreated as ServiceCreatedEvent } from "../generated/ServiceListing/ServiceListing"
import { handleServiceCreated } from "../src/service-listing"
import { createServiceCreatedEvent } from "./service-listing-utils"

// Tests structure (matchstick-as >=0.5.0)
// https://thegraph.com/docs/en/developer/matchstick/#tests-structure-0-5-0

describe("Describe entity assertions", () => {
  beforeAll(() => {
    let serviceId = BigInt.fromI32(234)
    let provider = Address.fromString(
      "0x0000000000000000000000000000000000000001"
    )
    let price = BigInt.fromI32(234)
    let ipfsHash = "Example string value"
    let newServiceCreatedEvent = createServiceCreatedEvent(
      serviceId,
      provider,
      price,
      ipfsHash
    )
    handleServiceCreated(newServiceCreatedEvent)
  })

  afterAll(() => {
    clearStore()
  })

  // For more test scenarios, see:
  // https://thegraph.com/docs/en/developer/matchstick/#write-a-unit-test

  test("ServiceCreated created and stored", () => {
    assert.entityCount("ServiceCreated", 1)

    // 0xa16081f360e3847006db660bae1c6d1b2e17ec2a is the default address used in newMockEvent() function
    assert.fieldEquals(
      "ServiceCreated",
      "0xa16081f360e3847006db660bae1c6d1b2e17ec2a-1",
      "serviceId",
      "234"
    )
    assert.fieldEquals(
      "ServiceCreated",
      "0xa16081f360e3847006db660bae1c6d1b2e17ec2a-1",
      "provider",
      "0x0000000000000000000000000000000000000001"
    )
    assert.fieldEquals(
      "ServiceCreated",
      "0xa16081f360e3847006db660bae1c6d1b2e17ec2a-1",
      "price",
      "234"
    )
    assert.fieldEquals(
      "ServiceCreated",
      "0xa16081f360e3847006db660bae1c6d1b2e17ec2a-1",
      "ipfsHash",
      "Example string value"
    )

    // More assert options:
    // https://thegraph.com/docs/en/developer/matchstick/#asserts
  })
})
