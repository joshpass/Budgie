//
//  CategoryPickerView.swift
//  Budgie
//
//  Created by Josh Pasricha on 19/12/22.
//

import SwiftUI

struct SectionedCategoryItem: Identifiable, Equatable {
    var id: String { primaryCategory.title ?? "" } // Retained for conformance to Identifiable
    var primaryCategory: Category
    var subCategories: [Category]?

    init(primaryCategory: Category, subCategories: [Category]? = []) {
        self.primaryCategory = primaryCategory
        self.subCategories = subCategories
    }
}

struct CategoryListView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.presentationMode) private var presenter

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(customSortDescriptor), NSSortDescriptor(lastLogSortDescriptor)],
        predicate: categoryPredicate()
    ) private var categories: FetchedResults<Category>

    @State var type: LogType = LogType.expense
    @FocusState private var focusedCategory: Focusable?

    var viewType: CategoryViewType
    @Binding var selectedCategory: Category?

    init(
        viewType: CategoryViewType = .addEdit,
        selectedCategory: Binding<Category?> = .constant(nil)
    ) {
        self.viewType = viewType
        _selectedCategory = selectedCategory
    }

    private static var customSortDescriptor: SortDescriptor<Category> = SortDescriptor(\Category.isCustom, order: .reverse)
    private static var lastLogSortDescriptor: SortDescriptor<Category> = SortDescriptor(\Category.lastLogDate, order: .reverse)
    private static func categoryPredicate(logType: LogType? = nil) -> NSPredicate {
        logType == nil ? NSPredicate(format: "parent == nil") : NSPredicate(format: "type == %@ && parent == nil", logType!.rawValue)
    }

    var body: some View {
        VStack(spacing: 24) {
            Group {
                switch viewType {
                    case .addEdit:
                        HStack(spacing: .zero) {
                            Spacer()
                            Button {
                                addParentOrStandaloneCategory()
                            } label: {
                                Image(systemName: "plus")
                                    .resizable()
                                    .frame(width: 24, height: 24)
                            }
                            .foregroundColor(.black)
                            .padding(.trailing, 24)
                        }.padding(.top, 24)

                    case .select:
                        HStack(spacing: .zero) {
                            Spacer()
                            Button {
                                presenter.wrappedValue.dismiss()
                            } label: {
                                Image(systemName: "xmark")
                                    .resizable()
                                    .frame(width: 24, height: 24)
                            }
                            .foregroundColor(.black)
                            .padding(.trailing, 24)
                        }.padding(.top, 24)
                }
            }
            Picker(
                "Type",
                selection: $type,
                content: {
                    ForEach(LogType.allCases, id: \.self) {
                        Text($0.rawValue.firstUpperCased)
                    }
                })
            .colorMultiply(.teal)
            .pickerStyle(.segmented)
            .padding(.horizontal, 24)
            .onChange(of: type) { newValue in withAnimation { categories.nsPredicate = CategoryListView.categoryPredicate(logType: newValue) } }

            sectionedCategoryListView()
        }
        .background(.black.opacity(0.07))
        .task { categories.nsPredicate = CategoryListView.categoryPredicate(logType: type) }
        .onDisappear {
            // TODO: This should be better than simply delete on disappear
            guard viewType == .addEdit else { return }
            // Delete nil categories. This will not delete subcategories, they will now become standalone
            categories
                .filter({ $0.isCustom && $0.title == nil })
                .forEach(viewContext.delete)
            // Delete nil subcategories
            (categories
                .filter({ $0.isParent })
                .flatMap({ $0.subCategories?.allObjects as! [Category] }))
                .filter({ $0.isCustom && $0.title == nil })
                .forEach(viewContext.delete)
            // If any parents have no subcategories, remove parent status so they can be deleted manually
            categories
                .filter({ $0.isParent && $0.subCategories!.allObjects.isEmpty })
                .forEach({ $0.isParent = false })
            PersistenceController.shared.save()
        }
    }

    @ViewBuilder func sectionedCategoryListView() -> some View {
        List {
            ForEach(categories) { category in
                Section {
                    // Standalone or Parent Category
                    categoryListItem(category: category)

                    // Subcategories
                    if let subcategories = category.subCategories?.allObjects as? [Category],
                       let sortedCategories = subcategories
                        .sorted(using: CategoryListView.customSortDescriptor)
                        .sorted(using: CategoryListView.lastLogSortDescriptor)
                    {
                        ForEach(sortedCategories) { subCategory in
                            categoryListItem(category: subCategory).padding(.leading, 20)
                        }
                        .onDelete {
                            if let parentIndex = categories.firstIndex(of: category) {
                                deleteSubCategories(at: $0, parentOffset: parentIndex)
                            }
                        }
                        .deleteDisabled(false)
                    }
                }.deleteDisabled(category.isParent)
            }.onDelete(perform: deleteStandaloneCategories)
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
    }

    @ViewBuilder func categoryListItem(category: Category) -> some View {
        HStack(spacing: 15) {
            Group {
                Image(systemName: "square.and.pencil.circle")
                    .resizable()
                    .frame(width: 24, height: 24)
                    .padding(.vertical, 3)

                TextField(
                    category.title ?? "New Category",
                    text: Binding(
                        get: { category.title ?? "" },
                        set: { category.title = $0 == "" ? nil : $0 }
                    )
                )
                .tint(viewType == .addEdit ? .black : .clear)
                .textInputAutocapitalization(.words)
                .font(.title3)
                .focused($focusedCategory, equals: .categoryRow(id: category.id))

                Spacer()
            }.onTapGesture {
                if viewType == .select && !category.isParent {
                    selectedCategory = category
                    presenter.wrappedValue.dismiss()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        category.lastLogDate = Date()
                        category.parent?.lastLogDate = Date()
                        PersistenceController.shared.save()
                    }
                }
            }

            if category.parent == nil {
                Button {
                    addSubCategory(parent: category)
                } label: {
                    Image(systemName: "plus")
                        .resizable()
                        .frame(width: 16, height: 16)
                }
                .foregroundColor(.black)
            }
        }
    }

    func addParentOrStandaloneCategory() {
        withAnimation {
            let newCategory = Category(context: viewContext)
            newCategory.isCustom = true
            newCategory.type = type.rawValue
            PersistenceController.shared.save()
            focusedCategory = .categoryRow(id: newCategory.id)
        }
    }

    func addSubCategory(parent: Category) {
        withAnimation {
            let newCategory = Category(context: viewContext)
            newCategory.isCustom = true
            newCategory.type = type.rawValue
            newCategory.parent = parent
            parent.isParent = true
            PersistenceController.shared.save()
            focusedCategory = .categoryRow(id: newCategory.id)
        }
    }

    func deleteStandaloneCategories(at offsets: IndexSet) {
        withAnimation {
            offsets.map { categories[$0] }.forEach(viewContext.delete)
            PersistenceController.shared.save()
        }
    }

    func deleteSubCategories(at offsets: IndexSet, parentOffset: Int) {
        withAnimation {
            offsets
                .map {(
                    (categories[parentOffset].subCategories?.allObjects as! [Category])
                        .sorted(using: CategoryListView.customSortDescriptor)
                        .sorted(using: CategoryListView.lastLogSortDescriptor)
                    )[$0]
                }
                .forEach { viewContext.delete($0) }
            PersistenceController.shared.save()
        }
        if categories[parentOffset].subCategories!.allObjects.isEmpty {
            categories[parentOffset].isParent = false
        }
        PersistenceController.shared.save()
    }
}

struct CategoryPickerView_Previews: PreviewProvider {
    static var previews: some View {
        CategoryListView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
