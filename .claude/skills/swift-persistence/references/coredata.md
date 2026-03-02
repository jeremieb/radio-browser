# CoreData Reference

**Minimum iOS**: 8.0+
**Import**: `import CoreData`

---

## Data model file

Create `MyApp.xcdatamodeld` via Xcode → File → New → Data Model.

- Entity names: **singular, UpperCamelCase** (`Task`, not `Tasks`)
- Add a **Codegen** class: `Manual/None` — always generate subclass manually
- Set module to **Current Product Module**

---

## NSManagedObject subclass

```swift
// Core/Models/Task+CoreDataClass.swift
import CoreData

@objc(Task)
public class Task: NSManagedObject {}
```

```swift
// Core/Models/Task+CoreDataProperties.swift
import CoreData

extension Task {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Task> {
        return NSFetchRequest<Task>(entityName: "Task")
    }

    @NSManaged public var title: String
    @NSManaged public var isCompleted: Bool
    @NSManaged public var dueDate: Date?
    @NSManaged public var project: Project?
}

extension Task: Identifiable {}
```

---

## PersistenceController

```swift
// Services/Storage/PersistenceController.swift
import CoreData

final class PersistenceController {

    static let shared = PersistenceController()

    // In-memory store for tests and Xcode Previews
    static let preview: PersistenceController = {
        let controller = PersistenceController(inMemory: true)
        let context = controller.container.viewContext
        // Seed preview data here
        let task = Task(context: context)
        task.title = "Preview Task"
        task.isCompleted = false
        try? context.save()
        return controller
    }()

    let container: NSPersistentContainer

    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "MyApp")
        if inMemory {
            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        }
        container.loadPersistentStores { _, error in
            if let error {
                fatalError("CoreData store failed to load: \(error)")
            }
        }
        container.viewContext.automaticallyMergesChangesFromParent = true
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
    func newTask() -> Task
}
```

---

## Repository implementation

```swift
// Services/Storage/TaskRepository.swift
import CoreData

final class TaskRepository: TaskRepositoryProtocol {
    private let context: NSManagedObjectContext

    init(context: NSManagedObjectContext = PersistenceController.shared.container.viewContext) {
        self.context = context
    }

    func fetchAll() throws -> [Task] {
        let request = Task.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "dueDate", ascending: true)]
        return try context.fetch(request)
    }

    func fetchPending() throws -> [Task] {
        let request = Task.fetchRequest()
        request.predicate = NSPredicate(format: "isCompleted == NO")
        request.sortDescriptors = [NSSortDescriptor(key: "dueDate", ascending: true)]
        return try context.fetch(request)
    }

    func save(_ task: Task) throws {
        try context.save()
    }

    func delete(_ task: Task) throws {
        context.delete(task)
        try context.save()
    }

    // Factory: creates a new Task in the context — caller sets properties before calling save()
    func newTask() -> Task {
        Task(context: context)
    }
}
```

---

## Background writes

Use `performBackgroundTask` for batch operations — never write to `viewContext` from a background thread:

```swift
func importTasks(_ items: [TaskPayload]) async throws {
    try await withCheckedThrowingContinuation { continuation in
        PersistenceController.shared.container.performBackgroundTask { context in
            do {
                for item in items {
                    let task = Task(context: context)
                    task.title = item.title
                    task.isCompleted = false
                }
                try context.save()
                continuation.resume()
            } catch {
                continuation.resume(throwing: error)
            }
        }
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
        let task = repository.newTask()
        task.title = title
        task.isCompleted = false
        do {
            try repository.save(task)
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

    // Use the in-memory store to create real NSManagedObjects for tests
    private let context = PersistenceController(inMemory: true).container.viewContext

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

    func newTask() -> Task {
        Task(context: context)
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

    @Test func test_when_loadTasks_should_populateTasks() throws {
        let mock = MockTaskRepository()
        let task = mock.newTask()
        task.title = "Buy milk"
        mock.stubbedTasks = [task]
        let sut = TaskListViewModel(repository: mock)

        sut.loadTasks()

        #expect(sut.tasks.count == 1)
        #expect(sut.tasks.first?.title == "Buy milk")
    }
}
```

---

## Migration

Create an `NSMappingModel` in Xcode when the schema changes. In PersistenceController:

```swift
container.loadPersistentStores { description, error in
    // ...
}
// Enable automatic lightweight migration for simple changes (add/rename column):
let description = container.persistentStoreDescriptions.first
description?.shouldMigrateStoreAutomatically = true
description?.shouldInferMappingModelAutomatically = true
```

For complex migrations (split entities, transform data), use a custom `NSMigrationManager` with an explicit mapping model — never rely on inference alone.
