import SwiftUI

struct BookingCreateView: View {
    @Bindable private var viewModel: BookingCreateViewModel

    init(viewModel: BookingCreateViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                dropoffCard
                pickupSection
                petSection
                scheduleSection
                notesField

                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .font(.footnote)
                        .foregroundStyle(.red)
                }

                submitButton

                if let bookingId = viewModel.createdBookingId {
                    NavigationLink("View Booking") {
                        BookingDetailView(viewModel: BookingDetailViewModel(bookingId: bookingId))
                    }
                    .buttonStyle(.bordered)
                }
            }
            .padding(20)
        }
        .navigationTitle("Book Delivery")
    }

    private var dropoffCard: some View {
        VStack(alignment: .leading, spacing: 6) {
            Label("Dropoff (pet shop)", systemImage: "flag.checkered")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            Text(viewModel.dropoffLabel)
                .font(.headline)
            Text(viewModel.dropoffPrefill.singleLineLabel)
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 8))
    }

    private var pickupSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Pickup address", systemImage: "mappin.and.ellipse")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            HStack {
                TextField("Where should the runner collect from?", text: $viewModel.pickupAddressText, axis: .vertical)
                    .textInputAutocapitalization(.words)
                    .padding()
                    .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 8))
                Button("Verify") {
                    Task { await viewModel.verifyPickup() }
                }
                .buttonStyle(.bordered)
                .disabled(viewModel.pickupVerifyState == .verifying)
            }

            switch viewModel.pickupVerifyState {
            case .idle:
                EmptyView()
            case .verifying:
                ProgressView()
            case .verified:
                if let resolved = viewModel.resolvedPickup {
                    Label(resolved.singleLineLabel, systemImage: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                        .font(.footnote)
                }
            case .failed(let message):
                Text(message)
                    .foregroundStyle(.red)
                    .font(.footnote)
            }
            validationText(for: "pickupAddress")
        }
    }

    private var petSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Pet details", systemImage: "pawprint.fill")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

            Picker("Pet type", selection: $viewModel.petType) {
                ForEach(BookingCreateViewModel.petTypes, id: \.self) { type in
                    Text(type.capitalized).tag(type)
                }
            }
            .pickerStyle(.segmented)

            field("Pet name", text: $viewModel.petName, key: "petName")
            field("Weight (kg)", text: $viewModel.petWeightKgText, key: "petWeightKg", keyboard: .decimalPad)
            field("Breed (optional)", text: $viewModel.breed, key: "breed")
            field("Special needs (optional)", text: $viewModel.specialNeeds, key: "specialNeeds")
        }
    }

    private var scheduleSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Toggle("Schedule for a specific time", isOn: $viewModel.hasSchedule)
            if viewModel.hasSchedule {
                DatePicker("When", selection: $viewModel.scheduledAt, in: Date()...)
                validationText(for: "scheduledAt")
            }
        }
    }

    private var notesField: some View {
        VStack(alignment: .leading, spacing: 6) {
            Label("Notes for the runner", systemImage: "note.text")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            TextField("Optional", text: $viewModel.notes, axis: .vertical)
                .lineLimit(3...5)
                .padding()
                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 8))
        }
    }

    private var submitButton: some View {
        Button {
            Task { await viewModel.submit() }
        } label: {
            HStack {
                if viewModel.isSubmitting {
                    ProgressView()
                        .tint(.white)
                }
                Text(viewModel.isSubmitting ? "Creating booking" : "Create booking")
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
        .disabled(viewModel.isSubmitting)
    }

    private func field(
        _ title: String,
        text: Binding<String>,
        key: String,
        keyboard: UIKeyboardType = .default
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            TextField(title, text: text)
                .keyboardType(keyboard)
                .padding()
                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 8))
            validationText(for: key)
        }
    }

    @ViewBuilder
    private func validationText(for key: String) -> some View {
        if let error = viewModel.fieldErrors[key] {
            Text(error)
                .font(.footnote)
                .foregroundStyle(.red)
        }
    }
}
