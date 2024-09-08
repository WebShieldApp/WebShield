//
//  LogsView.swift
//  WebShieldApp
//
//  Created by Arjun on 2024-09-08.
//

import Foundation
import SwiftUI

struct LogsView: View {
    let logs: String

    var body: some View {
        VStack(spacing: 20) {
            Text("Logs")
                .font(.largeTitle)
                .fontWeight(.bold)

            ScrollView {
                TextEditor(text: .constant(logs))
                    .font(.system(.body, design: .monospaced))
                    .background(Color(.textBackgroundColor))
                    .cornerRadius(8)
            }
            .background(Color(.textBackgroundColor))
            .cornerRadius(8)
        }
        .padding()
        .frame(width: 600, height: 400)
        .background(Color(.windowBackgroundColor))
    }
}
