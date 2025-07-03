//
//  MyApp.swift
//  airbank-ocr-demo
//
//  Created by Rosemary Yang on 7/2/25.
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
