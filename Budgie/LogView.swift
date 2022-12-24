//
//  LogView.swift
//  Budgie
//
//  Created by Josh Pasricha on 18/12/22.
//

import SwiftUI



struct LogView: View {
    @Environment(\.managedObjectContext) private var viewContext

    @State var amount: String = ""
    @State var timestamp: Date = Date()
    @State var category: Category?
    @State var excludedFromReport: Bool = false
    @State var notes: String = ""

    var viewType: LogViewType = .add
    @State var log: Log?

    @State var shouldPresentCategoryPicker = false

    @Environment(\.presentationMode) private var presenter
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Account.name, ascending: true)]
    )
    private var accounts: FetchedResults<Account>

    init(
        viewType: LogViewType = .add,
        log: Log? = nil
    ) {
        self.viewType = viewType
        _log = State(initialValue: log)
    }

    var body: some View {
        VStack(spacing: 24) {
            DatePicker(
                selection: $timestamp,
                in: ...Date(),
                label: {
                    Text("Date")
                        .padding(.leading, 5)
                        .font(.title3)
                        .fontWeight(.bold)
                }
            )
            .datePickerStyle(.compact)
            .padding(.vertical, 15)
            .fixedSize(horizontal: false, vertical: true)

            TextField("0.00", text: $amount)
                .textFieldStyle(LogTextFieldStyle(title: "Amount"))
                .fixedSize(horizontal: false, vertical: true)
                .keyboardType(.decimalPad)

            VStack(alignment: .leading, spacing: 10) {
                Text("Category")
                    .padding(.leading, 5)
                    .font(.title3)
                    .fontWeight(.bold)

                Button {
                    shouldPresentCategoryPicker = true
                } label: {
                    RoundedRectangle(cornerRadius: 15, style: .continuous)
                        .stroke(Color.black.opacity(0.5), lineWidth: 2.0)
                        .background(
                            HStack {
                                Text(category?.title ?? "Groceries")
                                    .foregroundColor(
                                        .black.opacity(category?.title == nil ? 0.23 : 1)
                                    )
                                    .padding(.leading, 25)
                                    .font(.title)
                                    .fontWeight(.bold)
                                Spacer()
                            }
                        ).frame(height: 65, alignment: .leading)
                        .contentShape(RoundedRectangle(cornerRadius: 15))
                }
                .buttonStyle(.plain)
                .sheet(isPresented: $shouldPresentCategoryPicker) {
                    CategoryListView(viewType: .select, selectedCategory: $category)
                }
            }

            TextField("Investment for...", text: $notes, axis: .vertical)
                .textFieldStyle(LogTextFieldStyle(title: "Notes"))
                .lineLimit(3)
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 24)

            Toggle(isOn: $excludedFromReport) {
                Text("Exclude from Reports")
                    .padding(.leading, 5)
                    .font(.title2)
            }.tint(.black)

            HStack(spacing: 24) {
                if viewType == .edit {
                    Button {
                        deleteLog()
                        presenter.wrappedValue.dismiss()
                    } label: {
                        RoundedRectangle(cornerRadius: 10)
                            .foregroundColor(.red)
                            .frame(height: 65)
                            .overlay {
                                Text("DELETE")
                                    .frame(alignment: .center)
                                    .padding(.leading, 5)
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                            }
                    }
                }

                Button {
                    saveLog()
                    presenter.wrappedValue.dismiss()
                } label: {
                    RoundedRectangle(cornerRadius: 10)
                        .foregroundColor(.black)
                        .frame(height: 65)
                        .overlay {
                            Text(viewType == .add ? "SAVE" : "UPDATE")
                                .frame(alignment: .center)
                                .padding(.leading, 5)
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                        }
                }
                .disabled(amount == "" || Float(amount) == .zero && category == nil)
            }

        }
        .padding(.horizontal, 24)
        .background(.black.opacity(0.07))
        .onAppear {
            if viewType == .edit {
                amount = log?.amount?.stringValue ?? ""
                timestamp = log?.timestamp ?? Date()
                category = log?.category
                excludedFromReport = log?.excludedFromReport ?? false
                notes = log?.notes ?? ""
            }
        }
    }

    func deleteLog() {
        guard log != nil else { return }
        switch LogType(rawValue: category!.type!) {
            case .expense: accounts.first?.balance = accounts.first?.balance?.adding(log!.amount!)
            case .income: accounts.first?.balance = accounts.first?.balance?.subtracting(log!.amount!)
            case .none: break
        }
        viewContext.delete(log!)
        PersistenceController.shared.save()
    }

    func saveLog() {
        switch viewType {
            case .add: log = Log(context: viewContext)
            case .edit: break
        }
        let oldAmount = log?.amount
        log?.amount = NSDecimalNumber(string: amount)
        log?.timestamp = timestamp
        log?.category = category
        log?.excludedFromReport = excludedFromReport
        log?.notes = notes
        if NSDecimalNumber(string: amount) != oldAmount {
            switch LogType(rawValue: category!.type!) {
                case .expense: accounts.first?.balance = accounts.first?.balance?.subtracting(log!.amount!)
                case .income: accounts.first?.balance = accounts.first?.balance?.adding(log!.amount!)
                case .none: break
            }
        }
        PersistenceController.shared.save()
    }
}

struct LogView_Previews: PreviewProvider {
    static var previews: some View {
        LogView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}

struct LogDatePickerStyle: DatePickerStyle {
    func makeBody(configuration: Configuration) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Date")
                .padding(.leading, 5)
                .font(.title3)
                .fontWeight(.bold)
            configuration.label
                .padding(.vertical, 15)
                .padding(.horizontal, 24)
                .background(
                    RoundedRectangle(cornerRadius: 15, style: .continuous)
                        .stroke(Color.black.opacity(0.5), lineWidth: 2.0)
                )
                .font(.title)
                .fontWeight(.bold)
        }
    }
}

struct LogTextFieldStyle: TextFieldStyle {
    var title: String
    func _body(configuration: TextField<Self._Label>) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .padding(.leading, 5)
                .font(.title3)
                .fontWeight(.bold)
            configuration
                .padding(.vertical, 15)
                .padding(.horizontal, 24)
                .background(
                    RoundedRectangle(cornerRadius: 15, style: .continuous)
                        .stroke(Color.black.opacity(0.5), lineWidth: 2.0)
                )
                .font(.title)
                .fontWeight(.bold)
        }
    }
}
