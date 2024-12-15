import {
  assert,
  describe,
  test,
  clearStore,
  beforeAll,
  afterAll
} from "matchstick-as/assembly/index"
import { BigInt, Address } from "@graphprotocol/graph-ts"
import { AgreementAcceptedByProvider } from "../generated/schema"
import { AgreementAcceptedByProvider as AgreementAcceptedByProviderEvent } from "../generated/ServiceAgreement/ServiceAgreement"
import { handleAgreementAcceptedByProvider } from "../src/service-agreement"
import { createAgreementAcceptedByProviderEvent } from "./service-agreement-utils"

// Tests structure (matchstick-as >=0.5.0)
// https://thegraph.com/docs/en/developer/matchstick/#tests-structure-0-5-0

describe("Describe entity assertions", () => {
  beforeAll(() => {
    let agreementId = BigInt.fromI32(234)
    let newAgreementAcceptedByProviderEvent =
      createAgreementAcceptedByProviderEvent(agreementId)
    handleAgreementAcceptedByProvider(newAgreementAcceptedByProviderEvent)
  })

  afterAll(() => {
    clearStore()
  })

  // For more test scenarios, see:
  // https://thegraph.com/docs/en/developer/matchstick/#write-a-unit-test

  test("AgreementAcceptedByProvider created and stored", () => {
    assert.entityCount("AgreementAcceptedByProvider", 1)

    // 0xa16081f360e3847006db660bae1c6d1b2e17ec2a is the default address used in newMockEvent() function
    assert.fieldEquals(
      "AgreementAcceptedByProvider",
      "0xa16081f360e3847006db660bae1c6d1b2e17ec2a-1",
      "agreementId",
      "234"
    )

    // More assert options:
    // https://thegraph.com/docs/en/developer/matchstick/#asserts
  })
})