import {
  assert,
  describe,
  test,
  clearStore,
  beforeAll,
  afterAll
} from "matchstick-as/assembly/index"
import { BigInt, Address } from "@graphprotocol/graph-ts"
import { FeedbackSubmitted } from "../generated/schema"
import { FeedbackSubmitted as FeedbackSubmittedEvent } from "../generated/ReputationManager/ReputationManager"
import { handleFeedbackSubmitted } from "../src/reputation-manager"
import { createFeedbackSubmittedEvent } from "./reputation-manager-utils"

// Tests structure (matchstick-as >=0.5.0)
// https://thegraph.com/docs/en/developer/matchstick/#tests-structure-0-5-0

describe("Describe entity assertions", () => {
  beforeAll(() => {
    let agreementId = BigInt.fromI32(234)
    let reviewer = Address.fromString(
      "0x0000000000000000000000000000000000000001"
    )
    let reviewee = Address.fromString(
      "0x0000000000000000000000000000000000000001"
    )
    let rating = 123
    let newFeedbackSubmittedEvent = createFeedbackSubmittedEvent(
      agreementId,
      reviewer,
      reviewee,
      rating
    )
    handleFeedbackSubmitted(newFeedbackSubmittedEvent)
  })

  afterAll(() => {
    clearStore()
  })

  // For more test scenarios, see:
  // https://thegraph.com/docs/en/developer/matchstick/#write-a-unit-test

  test("FeedbackSubmitted created and stored", () => {
    assert.entityCount("FeedbackSubmitted", 1)

    // 0xa16081f360e3847006db660bae1c6d1b2e17ec2a is the default address used in newMockEvent() function
    assert.fieldEquals(
      "FeedbackSubmitted",
      "0xa16081f360e3847006db660bae1c6d1b2e17ec2a-1",
      "agreementId",
      "234"
    )
    assert.fieldEquals(
      "FeedbackSubmitted",
      "0xa16081f360e3847006db660bae1c6d1b2e17ec2a-1",
      "reviewer",
      "0x0000000000000000000000000000000000000001"
    )
    assert.fieldEquals(
      "FeedbackSubmitted",
      "0xa16081f360e3847006db660bae1c6d1b2e17ec2a-1",
      "reviewee",
      "0x0000000000000000000000000000000000000001"
    )
    assert.fieldEquals(
      "FeedbackSubmitted",
      "0xa16081f360e3847006db660bae1c6d1b2e17ec2a-1",
      "rating",
      "123"
    )

    // More assert options:
    // https://thegraph.com/docs/en/developer/matchstick/#asserts
  })
})
