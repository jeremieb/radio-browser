# SwiftData Reference

**Minimum iOS**: 17.0
**Import**: `import SwiftData`

---

## Model definition

```swift
// Core/Models/Task.swift
import SwiftData

@Model
final class Task {
    var title: String
    var isCompleted: Bool
    var dueDate: Date?

    // One-to-many: a Task belongs to one Project
    var project: Project?

    init(title: String, isCompleted: Bool = false, dueDate: Date? = nil) {
        self.title = title
        self.isCompleted = isCompleted
        self.dueDate = dueDate
    }
}
```

Relationship annotations:
- `@Relationship(deleteRule: .cascade)` — delete children when parent is deleted
- `@Relationship(inverse: \Project.tasks)` — explicit inverse for bidirectional
- `@Transient` — exclude property from persistence

---

## PersistenceController

```swift
// Services/Storage/PersistenceController.swift
import SwiftData

@MainActor
final class PersistenceController {

    static let shared = PersistenceController()

    // In-memory store for tests and Xcode Previews
    static let preview: PersistenceController = {
        let controller = PersistenceController(inMemory: true)
        // Seed preview data here
        let context = controller.container.mainContext
        context.insert(Task(title: "Preview Task"))
        return controller
    }()

    let container: ModelContainer

    init(inMemory: Bool = false) {
        let schema = Schema([Task.self])
        let config = ModelConfiguration(isStoredInMemoryOnly: inMemory)
        do {
            container = try ModelContainer(for: schema, configurations: config)
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }
}
```

---

## Repository protocol

```swift
// Services/Storage/TaskRepositoryProtocol.swift
protocol TaskRepositoryProtocol {
    func fetchAll() throws -> [Task]
    func fetchPending() throws -> [Task]
    func save(_ task: Task) throws
    func delete(_ task: Task) throws
}
```

---

## Repository implementation

```swift
// Services/Storage/TaskRepository.swift
import SwiftData

final class TaskRepository: TaskRepositoryProtocol {
    private let context: ModelContext

    init(context: ModelContext = PersistenceController.shared.container.mainContext) {
        self.context = context
    }

    func fetchAll() throws -> [Task] {
        let descriptor = FetchDescriptor<Task>(sortBy: [SortDescriptor(\.dueDate)])
        return try context.fetch(descriptor)
    }

    func fetchPending() throws -> [Task] {
        let descriptor = FetchDescriptor<Task>(
            predicate: #Predicate { !$0.isCompleted },
            sortBy: [SortDescriptor(\.dueDate)]
        )
        return try context.fetch(descriptor)
    }

    func save(_ task: Task) throws {
        context.insert(task)
        try context.save()
    }

    func delete(_ task: Task) throws {
        context.delete(task)
        try context.save()
    }
}
```

---

## App entry point wiring

```swift
// App/MyApp.swift
import SwiftUI

@main
struct MyApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(PersistenceController.shared.container)
    }
}
```

---

## ViewModel (repository injected)

```swift
// Features/TaskList/TaskListViewModel.swift
import Foundation

@MainActor
@Observable
final class TaskListViewModel {
    private(set) var tasks: [Task] = []
    private(set) var errorMessage: String?

    private let repository: TaskRepositoryProtocol

    init(repository: TaskRepositoryProtocol = TaskRepository()) {
        self.repository = repository
    }

    func loadTasks() {
        do {
            tasks = try repository.fetchAll()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func addTask(title: String) {
        do {
            try repository.save(Task(title: title))
            loadTasks()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
```

---

## Mock for tests

```swift
// ProjectTests/Mocks/MockTaskRepository.swift
@testable import MyApp

final class MockTaskRepository: TaskRepositoryProtocol {
    var stubbedTasks: [Task] = []
    var saveCallCount = 0
    var deleteCallCount = 0
    var shouldThrow = false

    func fetchAll() throws -> [Task] {
        if shouldThrow { throw MockError.intentional }
        return stubbedTasks
    }

    func fetchPending() throws -> [Task] {
        if shouldThrow { throw MockError.intentional }
        return stubbedTasks.filter { !$0.isCompleted }
    }

    func save(_ task: Task) throws {
        if shouldThrow { throw MockError.intentional }
        saveCallCount += 1
    }

    func delete(_ task: Task) throws {
        if shouldThrow { throw MockError.intentional }
        deleteCallCount += 1
    }
}

enum MockError: Error { case intentional }
```

---

## Test setup (in-memory)

```swift
// ProjectTests/TaskListViewModelTests.swift
import Testing
@testable import MyApp

@MainActor
struct TaskListViewModelTests {

    @Test func test_when_loadTasks_should_populateTasks() {
        let mock = MockTaskRepository()
        mock.stubbedTasks = [Task(title: "Buy milk")]
        let sut = TaskListViewModel(repository: mock)

        sut.loadTasks()

        #expect(sut.tasks.count == 1)
        #expect(sut.tasks.first?.title == "Buy milk")
    }

    @Test func test_when_repositoryThrows_should_setErrorMessage() {
        let mock = MockTaskRepository()
        mock.shouldThrow = true
        let sut = TaskListViewModel(repository: mock)

        sut.loadTasks()

        #expect(sut.errorMessage != nil)
    }
}
```

---

## Schema migration

```swift
// Services/Storage/MigrationPlan.swift
import SwiftData

enum MyAppMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] = [
        SchemaV1.self,
        SchemaV2.self,
    ]
    static var stages: [MigrationStage] = [
        .lightweight(fromVersion: SchemaV1.self, toVersion: SchemaV2.self)
    ]
}
```

Always define versioned schemas explicitly — never rely on silent automatic migration.
