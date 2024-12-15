import { newMockEvent } from "matchstick-as"
import { ethereum, Address } from "@graphprotocol/graph-ts"
import {
  ArbitratorSet,
  ServiceAgreementAddressSet
} from "../generated/DisputeResolution/DisputeResolution"

export function createArbitratorSetEvent(
  newArbitrator: Address
): ArbitratorSet {
  let arbitratorSetEvent = changetype<ArbitratorSet>(newMockEvent())

  arbitratorSetEvent.parameters = new Array()

  arbitratorSetEvent.parameters.push(
    new ethereum.EventParam(
      "newArbitrator",
      ethereum.Value.fromAddress(newArbitrator)
    )
  )

  return arbitratorSetEvent
}

export function createServiceAgreementAddressSetEvent(
  newServiceAgreement: Address
): ServiceAgreementAddressSet {
  let serviceAgreementAddressSetEvent = changetype<ServiceAgreementAddressSet>(
    newMockEvent()
  )

  serviceAgreementAddressSetEvent.parameters = new Array()

  serviceAgreementAddressSetEvent.parameters.push(
    new ethereum.EventParam(
      "newServiceAgreement",
      ethereum.Value.fromAddress(newServiceAgreement)
    )
  )

  return serviceAgreementAddressSetEvent
}
