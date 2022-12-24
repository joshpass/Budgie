//
//  TabView.swift
//  Budgie
//
//  Created by Josh Pasricha on 14/12/22.
//

import SwiftUI
import CoreData

struct TabView: View {
    @Environment(\.managedObjectContext) private var viewContext

    /// Determines whether to present the Add Log sheet
    @State var shouldPresentAddTxnSheet = false
    /// Stores the value of the currently selected tab item
    @State private var selectedTabBarItem = 1
    /// Stores the value of the previously selected tab item before new tap
    @State private var previouslySelectedTabBarItem = 1


    var body: some View {
        ZStack(alignment: .bottom) {
            SwiftUI.TabView(selection: $selectedTabBarItem) {
                LogListView()
                    .modifier(TabItemBackgroundModifier())
                    .tabItem {
                        VStack {
                            Image(systemName: "square.and.pencil.circle")
                            Text("Expense List")
                                .fontWeight(.heavy)
                                .tint(.black)
                        }
                    }
                    .tag(1)
//                    .edgesIgnoringSafeArea(.top)

                Spacer()
                    .modifier(TabItemBackgroundModifier())
                    .tabItem {
                        VStack {
                            Image(systemName: "plus.circle")
                                .font(.title)
                            Text("Add Log")
                                .fontWeight(.heavy)
                                .tint(.black)
                        }
                    }
                    .tag(2)
                    .edgesIgnoringSafeArea(.top)


                CategoryListView()
                    .modifier(TabItemBackgroundModifier())
                    .tabItem {
                        VStack {
                            Image(systemName: "square.and.pencil.circle")
                            Text("Categories")
                                .fontWeight(.heavy)
                                .tint(.black)
                        }
                    }
                    .tag(3)
            }

            // Custom design of tab bar
            // Use tabitem for default design
//            HStack(spacing: .zero) {
//                VStack {
//                    Image(systemName: "square.and.pencil.circle")
//                        .resizable()
//                        .frame(width: 30, height: 30)
//                    Text("Logbook")
//                        .tint(.black)
//                }
//                Spacer()
//
//                VStack {
//                    Image(systemName: "plus.circle")
//                        .resizable()
//                        .frame(width: 64, height: 64)
//                }
//
//                Spacer()
//
//                VStack {
//                    Image(systemName: "square.and.pencil.circle")
//                        .resizable()
//                        .frame(width: 28, height: 28)
//                    Text("Categories")
//                        .tint(.black)
//                }
//
//            }
//            .padding([.horizontal, .bottom], 24)
//            .allowsHitTesting(false)
        }
        .edgesIgnoringSafeArea(.bottom)
        .tint(.black)
        .onChange(of: selectedTabBarItem) {
            if selectedTabBarItem == 2 {
                self.shouldPresentAddTxnSheet = true
                self.selectedTabBarItem = previouslySelectedTabBarItem
            }
            else { self.previouslySelectedTabBarItem = $0 }
        }
        .sheet(isPresented: $shouldPresentAddTxnSheet) {
            NavigationStack {
                LogView()
                    .navigationTitle("Add Log")
                    .toolbar {
                        Button {
                            shouldPresentAddTxnSheet = false
                        } label: {
                            Image(systemName: "xmark")
                                .resizable()
                                .frame(width: 24, height: 24)
                        }
                        .foregroundColor(.black)
                        .padding([.trailing, .top], 24)
                    }
            }
        }
        .onAppear {
            let appearance = UITabBarAppearance()
            appearance.backgroundEffect = nil
            appearance.backgroundColor = nil
            appearance.shadowColor = nil
            UITabBar.appearance().standardAppearance = appearance
            UITabBar.appearance().scrollEdgeAppearance = appearance
        }
    }

    struct TabItemBackgroundModifier: ViewModifier {
        func body(content: Content) -> some View {
            ZStack {
                content.frame(maxHeight: .infinity)
                VStack(spacing: .zero) {
                    Spacer()
                    Divider()
                    Rectangle()
                        .fill(Color.clear)
                        .frame(height: 100)
                        .background(Color.clear)
                        .background(Material.bar, in: Rectangle())
                }.ignoresSafeArea(edges: .bottom)
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        TabView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
