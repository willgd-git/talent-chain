import {
  assert,
  describe,
  test,
  clearStore,
  beforeAll,
  afterAll
} from "matchstick-as/assembly/index"
import { Address } from "@graphprotocol/graph-ts"
import { ArbitratorSet } from "../generated/schema"
import { ArbitratorSet as ArbitratorSetEvent } from "../generated/DisputeResolution/DisputeResolution"
import { handleArbitratorSet } from "../src/dispute-resolution"
import { createArbitratorSetEvent } from "./dispute-resolution-utils"

// Tests structure (matchstick-as >=0.5.0)
// https://thegraph.com/docs/en/developer/matchstick/#tests-structure-0-5-0

describe("Describe entity assertions", () => {
  beforeAll(() => {
    let newArbitrator = Address.fromString(
      "0x0000000000000000000000000000000000000001"
    )
    let newArbitratorSetEvent = createArbitratorSetEvent(newArbitrator)
    handleArbitratorSet(newArbitratorSetEvent)
  })

  afterAll(() => {
    clearStore()
  })

  // For more test scenarios, see:
  // https://thegraph.com/docs/en/developer/matchstick/#write-a-unit-test

  test("ArbitratorSet created and stored", () => {
    assert.entityCount("ArbitratorSet", 1)

    // 0xa16081f360e3847006db660bae1c6d1b2e17ec2a is the default address used in newMockEvent() function
    assert.fieldEquals(
      "ArbitratorSet",
      "0xa16081f360e3847006db660bae1c6d1b2e17ec2a-1",
      "newArbitrator",
      "0x0000000000000000000000000000000000000001"
    )

    // More assert options:
    // https://thegraph.com/docs/en/developer/matchstick/#asserts
  })
})
