import { newMockEvent } from "matchstick-as"
import { ethereum, BigInt, Address } from "@graphprotocol/graph-ts"
import {
  FundsDeposited,
  FundsDistributedAfterDispute,
  FundsRefunded,
  FundsReleased,
  ServiceAgreementAddressSet
} from "../generated/PaymentManager/PaymentManager"

export function createFundsDepositedEvent(
  agreementId: BigInt,
  amount: BigInt
): FundsDeposited {
  let fundsDepositedEvent = changetype<FundsDeposited>(newMockEvent())

  fundsDepositedEvent.parameters = new Array()

  fundsDepositedEvent.parameters.push(
    new ethereum.EventParam(
      "agreementId",
      ethereum.Value.fromUnsignedBigInt(agreementId)
    )
  )
  fundsDepositedEvent.parameters.push(
    new ethereum.EventParam("amount", ethereum.Value.fromUnsignedBigInt(amount))
  )

  return fundsDepositedEvent
}

export function createFundsDistributedAfterDisputeEvent(
  agreementId: BigInt,
  clientAmount: BigInt,
  providerAmount: BigInt
): FundsDistributedAfterDispute {
  let fundsDistributedAfterDisputeEvent =
    changetype<FundsDistributedAfterDispute>(newMockEvent())

  fundsDistributedAfterDisputeEvent.parameters = new Array()

  fundsDistributedAfterDisputeEvent.parameters.push(
    new ethereum.EventParam(
      "agreementId",
      ethereum.Value.fromUnsignedBigInt(agreementId)
    )
  )
  fundsDistributedAfterDisputeEvent.parameters.push(
    new ethereum.EventParam(
      "clientAmount",
      ethereum.Value.fromUnsignedBigInt(clientAmount)
    )
  )
  fundsDistributedAfterDisputeEvent.parameters.push(
    new ethereum.EventParam(
      "providerAmount",
      ethereum.Value.fromUnsignedBigInt(providerAmount)
    )
  )

  return fundsDistributedAfterDisputeEvent
}

export function createFundsRefundedEvent(
  agreementId: BigInt,
  amount: BigInt,
  to: Address
): FundsRefunded {
  let fundsRefundedEvent = changetype<FundsRefunded>(newMockEvent())

  fundsRefundedEvent.parameters = new Array()

  fundsRefundedEvent.parameters.push(
    new ethereum.EventParam(
      "agreementId",
      ethereum.Value.fromUnsignedBigInt(agreementId)
    )
  )
  fundsRefundedEvent.parameters.push(
    new ethereum.EventParam("amount", ethereum.Value.fromUnsignedBigInt(amount))
  )
  fundsRefundedEvent.parameters.push(
    new ethereum.EventParam("to", ethereum.Value.fromAddress(to))
  )

  return fundsRefundedEvent
}

export function createFundsReleasedEvent(
  agreementId: BigInt,
  amount: BigInt,
  to: Address
): FundsReleased {
  let fundsReleasedEvent = changetype<FundsReleased>(newMockEvent())

  fundsReleasedEvent.parameters = new Array()

  fundsReleasedEvent.parameters.push(
    new ethereum.EventParam(
      "agreementId",
      ethereum.Value.fromUnsignedBigInt(agreementId)
    )
  )
  fundsReleasedEvent.parameters.push(
    new ethereum.EventParam("amount", ethereum.Value.fromUnsignedBigInt(amount))
  )
  fundsReleasedEvent.parameters.push(
    new ethereum.EventParam("to", ethereum.Value.fromAddress(to))
  )

  return fundsReleasedEvent
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
