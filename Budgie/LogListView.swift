//
//  LogListView.swift
//  Budgie
//
//  Created by Josh Pasricha on 14/12/22.
//

import SwiftUI

struct DateMappedCalendarItems: Identifiable {
    var id: Date { date } // Retained for conformance to Identifiable
    var date: Date
    var items: [Log]
    var totalAmount: String

    init(date: Date, items: [Log]) {
        self.date = date
        self.items = items
        let totalAmount: NSDecimalNumber = items.reduce(0, { currentResult, currentLog in
            if currentLog.category?.type == LogType.expense.rawValue {
                return currentResult.subtracting(currentLog.amount!)
            } else if currentLog.category?.type == LogType.income.rawValue {
                return currentResult.adding(currentLog.amount!)
            }
            return currentResult
        })
        self.totalAmount = totalAmount.stringValue
        if totalAmount.decimalValue > .zero { self.totalAmount.insert("+", at: self.totalAmount.startIndex) }
    }
}

struct LogListView: View {
    @Environment(\.managedObjectContext) private var viewContext

    @FetchRequest( sortDescriptors: [NSSortDescriptor(keyPath: \Account.name, ascending: true)])
    private var accounts: FetchedResults<Account>

    @FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \Log.timestamp, ascending: false)])
    private var calendarItems: FetchedResults<Log>

    @State var currentMonth = Date()
    @State var presentEditLogSheetWithItem: Log?
    @State var searchFieldText: String = ""

    private var dateMappedCalendarItems: [DateMappedCalendarItems] {
        return calendarItems
            .sliced(by: [.year, .month, .day], for: \.timestamp!)
            .map { DateMappedCalendarItems(date: $0.key, items: $0.value) }
            .sorted { $0.date > $1.date }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: .zero) {
                if dateMappedCalendarItems.count == 0 {
                    VStack(spacing: .zero) {
                        monthSwitcher()
                        Spacer()
                        Text("Welcome \(accounts.first?.name?.split(separator: " ").first?.description ?? "Nameless")!\nNo Entries to show!")
                            .fontWeight(.medium)
                            .font(.title2)
                            .padding(.horizontal, 24)
                            .multilineTextAlignment(.center)
                        Spacer()
                    }
                } else { calendar() }
            }
            .searchable(text: $searchFieldText, placement: .navigationBarDrawer(displayMode: .automatic))
            .navigationTitle(Text("Balance: ₹\(accounts.first?.balance?.stringValue ?? "0.00")"))
            .navigationBarTitleDisplayMode(.large)
            .background(.black.opacity(0.07))
            .onChange(of: currentMonth) { calendarItems.nsPredicate = $0.monthPredicate() }
            .onChange(of: searchFieldText) { newValue in
                guard newValue != "" else { return calendarItems.nsPredicate = currentMonth.monthPredicate() }
                calendarItems.nsPredicate = NSPredicate(
                    format: "category.title CONTAINS[c] %@ || notes CONTAINS[c] %@", newValue, newValue
                )
            }.onAppear { if searchFieldText != "" { calendarItems.nsPredicate = currentMonth.monthPredicate() } }
        }
    }

    @ViewBuilder func monthSwitcher() -> some View {
        HStack(spacing: .zero) {
            Button(
                action: {
                    currentMonth = Calendar.current.date(byAdding: .month, value: -1, to: currentMonth) ?? Date()
                },
                label: {
                    Image(systemName: "chevron.left")
                        .resizable()
                        .tint(.black)
                        .frame(width: 20, height: 32)
                }
            )

            Spacer()

            Text(currentMonth.monthDisplayString())
                .fontWeight(.heavy)
                .font(.title)

            Spacer()

            Button(
                action: {
                    currentMonth = Calendar.autoupdatingCurrent.date(byAdding: .month, value: 1, to: currentMonth) ?? Date()
                },
                label: {
                    Image(systemName: "chevron.right")
                        .resizable()
                        .tint(.black)
                        .frame(width: 20, height: 32)
                }
            )
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 24)
        .background(
            Rectangle()
                .fill(Color.black.opacity(0.07))
                .frame(height: 100)
                .background(Material.bar, in: Rectangle())
        )
    }

    @ViewBuilder func calendar() -> some View {
        ScrollView {
            LazyVStack(pinnedViews: [.sectionHeaders]) {
                Section(header: monthSwitcher()) {
                    ForEach(dateMappedCalendarItems) { object in
                        Section(header: dateHeader(with: object.date, totalAmount: object.totalAmount)) {
                            VStack(spacing: .zero) {
                                ForEach(object.items) { item in
                                    itemRow(for: item)
                                }
                            }.padding(.bottom, 42)
                        }
                    }
                }
            }
        }
    }

    @ViewBuilder func itemRow(for item: Log) -> some View {
        VStack(spacing: .zero) {
            HStack(spacing: 10) {
                Image(systemName: "square.and.pencil.circle")
                    .resizable()
                    .frame(width: 48, height: 48)
                    .overlay(
                        Circle()
                        .stroke(item.category?.type == LogType.expense.rawValue ? Color.red : Color.green, lineWidth: 3)
                        .padding(-2)

                    )

                Text(item.category?.title ?? "Error")
                    .font(.title2)

                Spacer()

                VStack(alignment: .trailing, spacing: 10) {
                    Text(item.amount?.stringValue ?? "Error")
                        .fontWeight(.heavy)
                        .font(.title)

                    Text(item.timestamp?.time() ?? "Error")
                        .fontWeight(.heavy)
                        .font(.callout)
                        .foregroundColor(.black)
                }.padding(.vertical, 10)
            }

            Divider()
        }
        .padding(.horizontal, 24)
        .background(Color.gray.opacity(0.2))
        .onTapGesture { presentEditLogSheetWithItem = item }
        .sheet(item: self.$presentEditLogSheetWithItem) { log in
            NavigationStack {
                LogView(viewType: .edit, log: log)
                    .navigationTitle("Edit Log")
                    .toolbar {
                        Button {
                            presentEditLogSheetWithItem = nil
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
    }

    @ViewBuilder func dateHeader(with date: Date, totalAmount: String) -> some View {
        HStack(spacing: .zero) {
            Text(date.dateDisplayString(shouldDisplayMonthAndYear: searchFieldText != ""))
                .fontWeight(.heavy)
                .font(.callout)
            Spacer()
            Text(totalAmount)
                .fontWeight(.heavy)
                .font(.callout)
                .foregroundColor(Float(totalAmount) ?? 0 > 0 ? .green : .red)
        }.padding(.horizontal, 24)
    }
}

struct ExpenseListView_Previews: PreviewProvider {
    static var previews: some View {
        LogListView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}

extension RandomAccessCollection {
    func sliced(by dateComponents: Set<Calendar.Component>, for key: KeyPath<Element, Date>) -> [Date: [Element]] {
        let initial: [Date: [Element]] = [:]
        let groupedByDateComponents = reduce(into: initial) { acc, cur in
            let components = Calendar.current.dateComponents(dateComponents, from: cur[keyPath: key])
            let date = Calendar.current.date(from: components)!
            let existing = acc[date] ?? []
            acc[date] = existing + [cur]
        }
        return groupedByDateComponents
    }
}
