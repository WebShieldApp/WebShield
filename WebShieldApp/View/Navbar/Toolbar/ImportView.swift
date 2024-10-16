//
//  ImportView.swift
//  WebShieldApp
//
//  Created by Arjun on 2024-09-08.
//

import Foundation
import SwiftUI

struct ImportView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject private var filterListManager: FilterListManager
    @State private var urlsText: String = ""
    @State private var showingAlert = false
    @State private var alertMessage = ""

    var body: some View {
        VStack(spacing: 16) {
            Text("Import Filters")
                .font(.largeTitle)
                .padding(.top)

            Text("Enter one URL per line:")
                .font(.headline)

            ScrollView {
                TextEditor(text: $urlsText)
                    .frame(minHeight: 150)
                    .padding()
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.secondary, lineWidth: 1)
                    )
                    .padding([.leading, .trailing])
            }

            if !alertMessage.isEmpty {
                Text(alertMessage)
                    .foregroundColor(.red)
                    .font(.caption)
                    .padding()
            }

            Spacer()

            HStack {
                Button("Cancel") {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)

                Spacer()

                Button("Import") {
                    importFilterLists()
                }
                .disabled(
                    urlsText.trimmingCharacters(in: .whitespacesAndNewlines)
                        .isEmpty
                )
                .keyboardShortcut(.defaultAction)
            }
            .padding()
        }
        .padding()
        .frame(minWidth: 400, minHeight: 300)
        .alert("Import Results", isPresented: $showingAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(alertMessage)
        }
    }
    private func importFilterLists() {
        let lines =
            urlsText
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        var validURLs: [URL] = []
        var invalidURLs: [String] = []

        for line in lines {
            if let url = URL(string: line),
                url.scheme == "http" || url.scheme == "https"
            {
                validURLs.append(url)
            } else {
                invalidURLs.append(line)
            }
        }

        if !validURLs.isEmpty {
            filterListManager.addCustomFilterLists(urls: validURLs)
        }

        if !invalidURLs.isEmpty {
            alertMessage =
                "Some URLs were invalid and were not imported:\n"
                + invalidURLs.joined(separator: "\n")
        } else {
            alertMessage = "All URLs imported successfully!"
        }

        showingAlert = true
        dismiss()
    }
}
