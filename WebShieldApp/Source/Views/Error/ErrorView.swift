import SwiftUI

struct ErrorView: View {
    @EnvironmentObject var refreshErrorViewModel: RefreshErrorViewModel
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 60, weight: .regular))
                    .foregroundColor(.orange)
                    .padding(.top, 32)
                    .symbolEffect(.bounce, value: refreshErrorViewModel.errors)

                VStack(spacing: 8) {
                    Text("Refresh Failed")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)

                    Text("Some filter lists could not be updated")
                        .font(.headline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }

                ScrollView {
                    VStack(alignment: .leading, spacing: 12) {
                        ForEach(refreshErrorViewModel.errors) { error in
                            VStack(alignment: .leading, spacing: 4) {
                                Text(error.title)
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                Text(error.message)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.vertical, 8)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                    .padding(.horizontal)
                }

                Spacer()

                Button(action: {
                    refreshErrorViewModel.showErrorView = false
                    dismiss()
                }) {
                    Text("Try Again")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                }
                .buttonStyle(.borderedProminent)
                .padding(.horizontal)
                .padding(.bottom, 24)
            }
            .padding()
            .navigationTitle("Error Details")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Dismiss") {
                        dismiss()
                    }
                }
            }
        }
    }
}
