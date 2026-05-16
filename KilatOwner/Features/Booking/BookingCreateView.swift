import SwiftUI

struct BookingCreateView: View {
    @Bindable private var viewModel: BookingCreateViewModel

    init(viewModel: BookingCreateViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Shop \(viewModel.shopId)")
                    .font(.caption.weight(.semibold))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(.blue.opacity(0.12), in: Capsule())
                    .foregroundStyle(.blue)

                field("Pet name", text: $viewModel.petName, key: "petName")

                Picker("Pet type", selection: $viewModel.petType) {
                    ForEach(viewModel.petTypes, id: \.self) { type in
                        Text(type)
                    }
                }
                .pickerStyle(.segmented)

                field("Weight kg", text: $viewModel.petWeightKg, key: "petWeightKg", keyboard: .decimalPad)
                field("Dropoff address", text: $viewModel.dropoffAddress, key: "dropoffAddress")

                DatePicker("Scheduled time", selection: $viewModel.scheduledAt)
                validationText(for: "scheduledAt")

                TextField("Notes", text: $viewModel.notes, axis: .vertical)
                    .lineLimit(3...5)
                    .padding()
                    .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 8))

                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .font(.footnote)
                        .foregroundStyle(.red)
                }

                Button {
                    Task { await viewModel.submit() }
                } label: {
                    HStack {
                        if viewModel.isSubmitting {
                            ProgressView()
                                .tint(.white)
                        }
                        Text(viewModel.isSubmitting ? "Creating Booking" : "Create Booking")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(viewModel.isSubmitting)

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
