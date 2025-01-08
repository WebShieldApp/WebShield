import Foundation
import SwiftUI

struct NativeStyleTextEditor: View {
    @Binding var text: String
    var placeholder: String

    var body: some View {
        ZStack(alignment: .topLeading) {
            if text.isEmpty {
                Text(placeholder)
                    //                    .foregroundColor(Color(.placeholderTextColor))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 12)
            }
            TextEditor(text: $text)
                .padding(4)
        }
        .font(.body)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color(.systemGray), lineWidth: 1)
        )
            //        .background(Color(.textBackgroundColor))
    }
}
