import {
  assert,
  describe,
  test,
  clearStore,
  beforeAll,
  afterAll
} from "matchstick-as/assembly/index"
import { BigInt, Address } from "@graphprotocol/graph-ts"
import { FundsDeposited } from "../generated/schema"
import { FundsDeposited as FundsDepositedEvent } from "../generated/PaymentManager/PaymentManager"
import { handleFundsDeposited } from "../src/payment-manager"
import { createFundsDepositedEvent } from "./payment-manager-utils"

// Tests structure (matchstick-as >=0.5.0)
// https://thegraph.com/docs/en/developer/matchstick/#tests-structure-0-5-0

describe("Describe entity assertions", () => {
  beforeAll(() => {
    let agreementId = BigInt.fromI32(234)
    let amount = BigInt.fromI32(234)
    let newFundsDepositedEvent = createFundsDepositedEvent(agreementId, amount)
    handleFundsDeposited(newFundsDepositedEvent)
  })

  afterAll(() => {
    clearStore()
  })

  // For more test scenarios, see:
  // https://thegraph.com/docs/en/developer/matchstick/#write-a-unit-test

  test("FundsDeposited created and stored", () => {
    assert.entityCount("FundsDeposited", 1)

    // 0xa16081f360e3847006db660bae1c6d1b2e17ec2a is the default address used in newMockEvent() function
    assert.fieldEquals(
      "FundsDeposited",
      "0xa16081f360e3847006db660bae1c6d1b2e17ec2a-1",
      "agreementId",
      "234"
    )
    assert.fieldEquals(
      "FundsDeposited",
      "0xa16081f360e3847006db660bae1c6d1b2e17ec2a-1",
      "amount",
      "234"
    )

    // More assert options:
    // https://thegraph.com/docs/en/developer/matchstick/#asserts
  })
})
