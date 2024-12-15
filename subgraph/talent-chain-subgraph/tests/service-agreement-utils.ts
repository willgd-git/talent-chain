import { newMockEvent } from "matchstick-as"
import { ethereum, BigInt, Address } from "@graphprotocol/graph-ts"
import {
  AgreementAcceptedByProvider,
  AgreementAmountUpdated,
  AgreementCancelled,
  AgreementCompleted,
  AgreementCompletedAccepted,
  AgreementCreated,
  AgreementDisputeResolved,
  AgreementDisputed,
  AgreementPaid,
  PaymentManagerAddressSet,
  ServiceListingAddressSet
} from "../generated/ServiceAgreement/ServiceAgreement"

export function createAgreementAcceptedByProviderEvent(
  agreementId: BigInt
): AgreementAcceptedByProvider {
  let agreementAcceptedByProviderEvent =
    changetype<AgreementAcceptedByProvider>(newMockEvent())

  agreementAcceptedByProviderEvent.parameters = new Array()

  agreementAcceptedByProviderEvent.parameters.push(
    new ethereum.EventParam(
      "agreementId",
      ethereum.Value.fromUnsignedBigInt(agreementId)
    )
  )

  return agreementAcceptedByProviderEvent
}

export function createAgreementAmountUpdatedEvent(
  agreementId: BigInt,
  oldAmount: BigInt,
  newAmount: BigInt
): AgreementAmountUpdated {
  let agreementAmountUpdatedEvent = changetype<AgreementAmountUpdated>(
    newMockEvent()
  )

  agreementAmountUpdatedEvent.parameters = new Array()

  agreementAmountUpdatedEvent.parameters.push(
    new ethereum.EventParam(
      "agreementId",
      ethereum.Value.fromUnsignedBigInt(agreementId)
    )
  )
  agreementAmountUpdatedEvent.parameters.push(
    new ethereum.EventParam(
      "oldAmount",
      ethereum.Value.fromUnsignedBigInt(oldAmount)
    )
  )
  agreementAmountUpdatedEvent.parameters.push(
    new ethereum.EventParam(
      "newAmount",
      ethereum.Value.fromUnsignedBigInt(newAmount)
    )
  )

  return agreementAmountUpdatedEvent
}

export function createAgreementCancelledEvent(
  agreementId: BigInt
): AgreementCancelled {
  let agreementCancelledEvent = changetype<AgreementCancelled>(newMockEvent())

  agreementCancelledEvent.parameters = new Array()

  agreementCancelledEvent.parameters.push(
    new ethereum.EventParam(
      "agreementId",
      ethereum.Value.fromUnsignedBigInt(agreementId)
    )
  )

  return agreementCancelledEvent
}

export function createAgreementCompletedEvent(
  agreementId: BigInt
): AgreementCompleted {
  let agreementCompletedEvent = changetype<AgreementCompleted>(newMockEvent())

  agreementCompletedEvent.parameters = new Array()

  agreementCompletedEvent.parameters.push(
    new ethereum.EventParam(
      "agreementId",
      ethereum.Value.fromUnsignedBigInt(agreementId)
    )
  )

  return agreementCompletedEvent
}

export function createAgreementCompletedAcceptedEvent(
  agreementId: BigInt
): AgreementCompletedAccepted {
  let agreementCompletedAcceptedEvent = changetype<AgreementCompletedAccepted>(
    newMockEvent()
  )

  agreementCompletedAcceptedEvent.parameters = new Array()

  agreementCompletedAcceptedEvent.parameters.push(
    new ethereum.EventParam(
      "agreementId",
      ethereum.Value.fromUnsignedBigInt(agreementId)
    )
  )

  return agreementCompletedAcceptedEvent
}

export function createAgreementCreatedEvent(
  agreementId: BigInt,
  serviceId: BigInt,
  client: Address,
  provider: Address,
  amount: BigInt
): AgreementCreated {
  let agreementCreatedEvent = changetype<AgreementCreated>(newMockEvent())

  agreementCreatedEvent.parameters = new Array()

  agreementCreatedEvent.parameters.push(
    new ethereum.EventParam(
      "agreementId",
      ethereum.Value.fromUnsignedBigInt(agreementId)
    )
  )
  agreementCreatedEvent.parameters.push(
    new ethereum.EventParam(
      "serviceId",
      ethereum.Value.fromUnsignedBigInt(serviceId)
    )
  )
  agreementCreatedEvent.parameters.push(
    new ethereum.EventParam("client", ethereum.Value.fromAddress(client))
  )
  agreementCreatedEvent.parameters.push(
    new ethereum.EventParam("provider", ethereum.Value.fromAddress(provider))
  )
  agreementCreatedEvent.parameters.push(
    new ethereum.EventParam("amount", ethereum.Value.fromUnsignedBigInt(amount))
  )

  return agreementCreatedEvent
}

export function createAgreementDisputeResolvedEvent(
  agreementId: BigInt,
  ruling: i32
): AgreementDisputeResolved {
  let agreementDisputeResolvedEvent = changetype<AgreementDisputeResolved>(
    newMockEvent()
  )

  agreementDisputeResolvedEvent.parameters = new Array()

  agreementDisputeResolvedEvent.parameters.push(
    new ethereum.EventParam(
      "agreementId",
      ethereum.Value.fromUnsignedBigInt(agreementId)
    )
  )
  agreementDisputeResolvedEvent.parameters.push(
    new ethereum.EventParam(
      "ruling",
      ethereum.Value.fromUnsignedBigInt(BigInt.fromI32(ruling))
    )
  )

  return agreementDisputeResolvedEvent
}

export function createAgreementDisputedEvent(
  agreementId: BigInt
): AgreementDisputed {
  let agreementDisputedEvent = changetype<AgreementDisputed>(newMockEvent())

  agreementDisputedEvent.parameters = new Array()

  agreementDisputedEvent.parameters.push(
    new ethereum.EventParam(
      "agreementId",
      ethereum.Value.fromUnsignedBigInt(agreementId)
    )
  )

  return agreementDisputedEvent
}

export function createAgreementPaidEvent(agreementId: BigInt): AgreementPaid {
  let agreementPaidEvent = changetype<AgreementPaid>(newMockEvent())

  agreementPaidEvent.parameters = new Array()

  agreementPaidEvent.parameters.push(
    new ethereum.EventParam(
      "agreementId",
      ethereum.Value.fromUnsignedBigInt(agreementId)
    )
  )

  return agreementPaidEvent
}

export function createPaymentManagerAddressSetEvent(
  newPaymentManager: Address
): PaymentManagerAddressSet {
  let paymentManagerAddressSetEvent = changetype<PaymentManagerAddressSet>(
    newMockEvent()
  )

  paymentManagerAddressSetEvent.parameters = new Array()

  paymentManagerAddressSetEvent.parameters.push(
    new ethereum.EventParam(
      "newPaymentManager",
      ethereum.Value.fromAddress(newPaymentManager)
    )
  )

  return paymentManagerAddressSetEvent
}

export function createServiceListingAddressSetEvent(
  newServiceListing: Address
): ServiceListingAddressSet {
  let serviceListingAddressSetEvent = changetype<ServiceListingAddressSet>(
    newMockEvent()
  )

  serviceListingAddressSetEvent.parameters = new Array()

  serviceListingAddressSetEvent.parameters.push(
    new ethereum.EventParam(
      "newServiceListing",
      ethereum.Value.fromAddress(newServiceListing)
    )
  )

  return serviceListingAddressSetEvent
}
