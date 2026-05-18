import Foundation

struct StubAuthRepository: AuthRepository {
    func login(email: String, password: String) async throws -> LoginResponse {
        LoginResponse(
            accessToken: "stub-access-token",
            refreshToken: "stub-refresh-token",
            user: SampleData.ownerProfile
        )
    }

    func register(_ request: RegisterRequest) async throws -> LoginResponse {
        LoginResponse(
            accessToken: "stub-access-token",
            refreshToken: "stub-refresh-token",
            user: SampleData.ownerProfile
        )
    }

    func forgotPassword(email: String) async throws {}

    func resetPassword(token: String, newPassword: String) async throws {}

    func profile() async throws -> ProfileDTO {
        SampleData.ownerProfile
    }

    func logout() async throws {}
}

struct StubBookingRepository: BookingRepository {
    func create(_ request: CreateBookingRequest) async throws -> BookingDTO {
        SampleData.activeBooking
    }

    func get(id: String) async throws -> BookingDTO {
        if id == SampleData.completedBooking.id.uuidString {
            return SampleData.completedBooking
        }
        return SampleData.activeBooking
    }

    func listActive() async throws -> [BookingDTO] {
        [SampleData.activeBooking]
    }

    func listRecent() async throws -> [BookingDTO] {
        [SampleData.completedBooking]
    }

    func cancel(id: String, reason: CancelReason, freeText: String = "") async throws -> BookingDTO {
        let original = try await get(id: id)
        return BookingDTO(
            id: original.id,
            bookingNumber: original.bookingNumber,
            ownerID: original.ownerID,
            runnerID: original.runnerID,
            status: .cancelled,
            petSpec: original.petSpec,
            crateRequirement: original.crateRequirement,
            pickupAddress: original.pickupAddress,
            dropoffAddress: original.dropoffAddress,
            routeSpec: original.routeSpec,
            estimatedPriceCents: original.estimatedPriceCents,
            finalPriceCents: original.finalPriceCents,
            currency: original.currency,
            scheduledAt: original.scheduledAt,
            pickedUpAt: original.pickedUpAt,
            deliveredAt: original.deliveredAt,
            cancelledAt: SampleData.baseDate,
            cancelNote: reason.wireReason(freeText: freeText),
            notes: original.notes,
            version: original.version + 1,
            createdAt: original.createdAt,
            updatedAt: SampleData.baseDate
        )
    }
}

struct StubPaymentRepository: PaymentRepository {
    func initiate(
        bookingID: String,
        amountCents: Int64,
        currency: String,
        customerEmail: String
    ) async throws -> InitiatePaymentResponse {
        SampleData.paymentInitiation
    }

    func pollEscrow(bookingID: String) async throws -> PaymentDTO {
        SampleData.payment
    }
}

struct StubPetRepository: PetRepository {
    func listMyPets() async throws -> [PetDTO] {
        [SampleData.mochiPet, SampleData.baoPet]
    }

    func createPet(_ request: CreatePetRequest) async throws -> PetDTO {
        PetDTO(
            id: UUID(),
            ownerID: SampleData.ownerID,
            name: request.name,
            petType: request.petType,
            breed: request.breed,
            weightKg: request.weightKg,
            ageMonths: request.ageMonths,
            allergies: request.allergies,
            specialNeeds: request.specialNeeds,
            notes: request.notes,
            photoURL: request.photoURL,
            vaccinationStatus: request.vaccinationStatus,
            status: "active",
            createdAt: SampleData.baseDate,
            updatedAt: SampleData.baseDate
        )
    }
}

struct StubNotificationRepository: NotificationRepository {
    func list(cursor: String?, limit: Int) async throws -> NotificationListDTO {
        NotificationListDTO(
            items: Array(SampleData.notifications.prefix(limit)),
            nextCursor: ""
        )
    }

    func markRead(id: String) async throws {}
}

final class StubTrackingRepository: TrackingRepository {
    func subscribe(
        bookingID: String,
        onUpdate: @escaping @Sendable (TrackingEvent) -> Void,
        onDisconnect: @escaping @Sendable () -> Void
    ) -> TrackingSubscription {
        let task = Task {
            for index in 0..<5 {
                guard !Task.isCancelled else { return }
                let progress = Double(index) / 4.0
                let update = TrackingLocationUpdate(
                    bookingID: bookingID,
                    runnerID: Personas.aiman.id,
                    latitude: SampleData.pickupAddress.latitude
                        + (SampleData.dropoffAddress.latitude - SampleData.pickupAddress.latitude) * progress,
                    longitude: SampleData.pickupAddress.longitude
                        + (SampleData.dropoffAddress.longitude - SampleData.pickupAddress.longitude) * progress,
                    speedKmh: 28,
                    headingDegrees: 110,
                    timestamp: SampleData.baseDate.addingTimeInterval(Double(index) * 0.4)
                )
                onUpdate(.location(update))
                try? await Task.sleep(nanoseconds: 400_000_000)
            }
            onDisconnect()
        }
        return StubTrackingSubscription(task: task)
    }
}

struct StubHomeRepository: HomeRepository {
    func snapshot() async throws -> HomeSnapshot {
        SampleData.homeSnapshot
    }
}

private final class StubTrackingSubscription: TrackingSubscription {
    private let task: Task<Void, Never>

    init(task: Task<Void, Never>) {
        self.task = task
    }

    func cancel() {
        task.cancel()
    }
}
