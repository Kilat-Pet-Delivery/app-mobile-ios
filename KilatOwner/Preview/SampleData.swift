import Foundation

enum SampleData {
    static let ownerID = uuid("00000000-0000-0000-0000-000000000001")
    static let runnerID = uuid("00000000-0000-0000-0000-000000000002")
    static let mochiID = uuid("00000000-0000-0000-0000-000000000101")
    static let baoID = uuid("00000000-0000-0000-0000-000000000102")
    static let activeBookingID = uuid("11111111-1111-1111-1111-111111111111")
    static let completedBookingID = uuid("11111111-1111-1111-1111-111111111112")
    static let paymentID = uuid("22222222-2222-2222-2222-222222222222")

    static let baseDate = Date(timeIntervalSince1970: 1_779_080_400)

    static let ownerProfile = ProfileDTO(
        id: ownerID,
        email: Personas.ownerEmail,
        phone: "+60123456789",
        fullName: Personas.ownerName,
        role: "owner",
        isVerified: true,
        avatarURL: nil,
        createdAt: baseDate
    )

    static let pickupAddress = AddressDTO(
        line1: Personas.ownerAddressLine,
        line2: "",
        city: "Kuala Lumpur",
        state: "WP Kuala Lumpur",
        postalCode: "50450",
        country: "MY",
        latitude: 3.1599,
        longitude: 101.7123
    )

    static let dropoffAddress = AddressDTO(
        line1: "Kilat Vet Clinic",
        line2: "Lot G-12",
        city: "Kuala Lumpur",
        state: "WP Kuala Lumpur",
        postalCode: "50450",
        country: "MY",
        latitude: 3.1478,
        longitude: 101.6953
    )

    static let mochiPet = PetDTO(
        id: mochiID,
        ownerID: ownerID,
        name: Personas.mochiName,
        petType: .cat,
        breed: "Calico",
        weightKg: 4.2,
        ageMonths: 36,
        allergies: "",
        specialNeeds: "Keep carrier covered",
        notes: "Gentle, nervous around traffic",
        photoURL: "",
        vaccinationStatus: "verified",
        status: "active",
        createdAt: baseDate,
        updatedAt: baseDate
    )

    static let baoPet = PetDTO(
        id: baoID,
        ownerID: ownerID,
        name: Personas.baoName,
        petType: .dog,
        breed: "Golden retriever",
        weightKg: 18,
        ageMonths: 48,
        allergies: "",
        specialNeeds: "Use medium crate",
        notes: "Friendly with runners",
        photoURL: "",
        vaccinationStatus: "verified",
        status: "active",
        createdAt: baseDate,
        updatedAt: baseDate
    )

    static let routeSpec = RouteSpecDTO(
        pickupLat: pickupAddress.latitude,
        pickupLng: pickupAddress.longitude,
        dropoffLat: dropoffAddress.latitude,
        dropoffLng: dropoffAddress.longitude,
        distanceKm: 4.8,
        estimatedDurationMin: 18,
        polyline: "stub-route"
    )

    static let crateRequirement = CrateRequirementDTO(
        minimumSize: "small",
        needsVentilation: true,
        needsTempControl: false,
        minimumWeightCapacity: 5.04
    )

    static let activeBooking = BookingDTO(
        id: activeBookingID,
        bookingNumber: "KLT-2026-0001",
        ownerID: ownerID,
        runnerID: runnerID,
        status: .inProgress,
        petSpec: mochiPet.spec,
        crateRequirement: crateRequirement,
        pickupAddress: pickupAddress,
        dropoffAddress: dropoffAddress,
        routeSpec: routeSpec,
        estimatedPriceCents: 1800,
        finalPriceCents: nil,
        currency: "MYR",
        scheduledAt: baseDate.addingTimeInterval(1_800),
        pickedUpAt: baseDate.addingTimeInterval(2_700),
        deliveredAt: nil,
        cancelledAt: nil,
        cancelNote: "",
        notes: "Mochi gets nervous around traffic",
        version: 2,
        createdAt: baseDate,
        updatedAt: baseDate.addingTimeInterval(2_700)
    )

    static let completedBooking = BookingDTO(
        id: completedBookingID,
        bookingNumber: "KLT-2026-0000",
        ownerID: ownerID,
        runnerID: runnerID,
        status: .completed,
        petSpec: baoPet.spec,
        crateRequirement: CrateRequirementDTO(
            minimumSize: "large",
            needsVentilation: true,
            needsTempControl: false,
            minimumWeightCapacity: 21.6
        ),
        pickupAddress: pickupAddress,
        dropoffAddress: dropoffAddress,
        routeSpec: routeSpec,
        estimatedPriceCents: 2800,
        finalPriceCents: 2800,
        currency: "MYR",
        scheduledAt: baseDate.addingTimeInterval(-86_400),
        pickedUpAt: baseDate.addingTimeInterval(-84_900),
        deliveredAt: baseDate.addingTimeInterval(-83_700),
        cancelledAt: nil,
        cancelNote: "",
        notes: "Bao daycare pickup",
        version: 4,
        createdAt: baseDate.addingTimeInterval(-90_000),
        updatedAt: baseDate.addingTimeInterval(-83_700)
    )

    static let payment = PaymentDTO(
        id: paymentID,
        bookingID: activeBookingID,
        ownerID: ownerID,
        runnerID: runnerID,
        escrowStatus: .held,
        amountCents: activeBooking.amountCents,
        platformFeeCents: 360,
        runnerPayoutCents: 1440,
        currency: "MYR",
        paymentMethod: "stripe",
        stripePaymentID: "pi_stub_123",
        escrowHeldAt: baseDate.addingTimeInterval(2_400),
        escrowReleasedAt: nil,
        refundedAt: nil,
        refundReason: "",
        version: 1,
        createdAt: baseDate.addingTimeInterval(2_300),
        updatedAt: baseDate.addingTimeInterval(2_400)
    )

    static let paymentInitiation = InitiatePaymentResponse(
        id: paymentID,
        bookingID: activeBookingID,
        amountCents: activeBooking.amountCents,
        currency: "MYR",
        escrowStatus: .pending,
        redirectURL: URL(string: "https://checkout.stripe.test/pay/cs_stub"),
        paymentIntentID: "pi_stub_123"
    )

    static let notifications = [
        NotificationDTO(
            id: "notif-1",
            type: .bookingAccepted,
            title: "Runner assigned",
            body: "Aiman is on the way for Mochi.",
            createdAt: baseDate.addingTimeInterval(2_100),
            readAt: nil
        ),
        NotificationDTO(
            id: "notif-2",
            type: .paymentEscrowHeld,
            title: "Payment authorized",
            body: "RM18.00 is held safely until delivery.",
            createdAt: baseDate.addingTimeInterval(2_400),
            readAt: baseDate.addingTimeInterval(2_800)
        )
    ]

    static let homeSnapshot = HomeSnapshot(
        activeBooking: activeBooking,
        pets: [mochiPet, baoPet],
        recentTrips: [completedBooking],
        unreadNotificationCount: 1
    )

    private static func uuid(_ value: String) -> UUID {
        guard let uuid = UUID(uuidString: value) else {
            preconditionFailure("Invalid sample UUID: \(value)")
        }
        return uuid
    }
}
