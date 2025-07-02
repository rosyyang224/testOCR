//
//  MyApp.swift
//  airbank-ocr-demo
//
//  Created by Rosemary Yang on 7/2/25.
//  Copyright © 2025 Marek Přidal. All rights reserved.
//

import SwiftUI

@main
struct MyApp: App {
    init() {
        AppTheme.apply()
    }

    var body: some Scene {
        WindowGroup {
            MainHomeView()
        }
    }
}
