//
//  PulseEffect.swift
//  WebShield
//
//  Created by Arjun on 2024-10-12.
//

import SwiftUI

struct PulsatingEffect: ViewModifier {
    var apply: Bool
    @State private var animate = false

    func body(content: Content) -> some View {
        content
            .scaleEffect(animate ? 1.0 : 1.1)
            .animation(
                apply
                    ? Animation.easeInOut(duration: 0.8).repeatForever(
                        autoreverses: true) : .default,
                value: animate
            )
            .onChange(of: apply) {
                animate = apply
            }
            .onAppear {
                animate = apply
            }
    }
}
