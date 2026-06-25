//
//  ttp_testApp.swift
//  ttp-test
//
//  Created by Jian Liang Job Seow on 24/6/26.
//

import SwiftUI
import StripeTerminal


@main
struct ttp_testApp: App {
    init() {
        Terminal.initWithTokenProvider(APIClient.shared)
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
