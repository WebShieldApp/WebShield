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
    @State private var url = ""

    var body: some View {
        Text("Import Filter List").font(.title).fontWeight(.bold).padding()
        Text("One URL per line. Invalid URLs will be silently ignored.")
            .padding()
        NativeStyleTextEditor(
            text: $url,
            placeholder:
                "One URL per line. Invalid URLs will be silently ignored."
        )
        .frame(minHeight: 200)
        //        .font(.body)
        //        .border(Color.gray, width: 1)
        .padding()
        HStack {
            Button("OK", action: submit)
            Button("Cancel") {
                dismiss()
            }
        }.padding()
    }
    func submit() {
        print("You entered \(url)")
    }
}
