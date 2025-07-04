//
//  KeyValueRowView.swift
//  airbank-ocr-demo
//
//  Created by Rosemary Yang on 7/3/25.
//  Copyright © 2025 Marek Přidal. All rights reserved.
//


import SwiftUI

struct KeyValueRowView: View {
    var key: String
    var value: String

    var body: some View {
        HStack {
            Text(key)
                .font(.subheadline)
                .fontWeight(.semibold)
            Spacer()
            Text(value)
                .font(.subheadline)
                .multilineTextAlignment(.trailing)
        }
        .padding()
        .background(.background)
        .cornerRadius(10)
    }
}
