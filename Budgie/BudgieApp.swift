//
//  BudgieApp.swift
//  Budgie
//
//  Created by Josh Pasricha on 14/12/22.
//

import SwiftUI

@main
struct BudgieApp: App {
    @Environment(\.scenePhase) var scenePhase
    let persistenceController = PersistenceController.shared
    @AppStorage("isLoggedIn") private var isLoggedIn = false

    var body: some Scene {
        WindowGroup {
            switch isLoggedIn {
                case false: LoginSignUpView().environment(\.managedObjectContext, persistenceController.container.viewContext)
                case true: TabView().environment(\.managedObjectContext, persistenceController.container.viewContext)
            }
        }
        .onChange(of: scenePhase) { _ in
            persistenceController.save()
        }
    }
}
