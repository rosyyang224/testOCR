//
//  PassportIllustration.swift
//  airbank-ocr-demo
//
//  Created by Rosemary Yang on 7/3/25.
//  Copyright © 2025 Marek Přidal. All rights reserved.
//


import SwiftUI

struct PassportIllustration: View {
    var body: some View {
        ZStack {
            VStack {
                Spacer()
                Text("PASSPORT")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.bottom, 20)
            }
            .frame(width: 200, height: 140)
            .background(AppTheme.darkBlue)
            .cornerRadius(8)

            Circle()
                .fill(Color.white.opacity(0.3))
                .frame(width: 40, height: 40)
                .offset(y: -30)
        }
    }
}
