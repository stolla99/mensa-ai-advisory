import Foundation
import CoreData

class CoreDataStack: ObservableObject {
    static let shared = CoreDataStack()
    
    @Published var mensaDays: [MensaDay] = []
    
    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "MensaModel")
        container.loadPersistentStores(completionHandler: { _, error in
            if let error {
                fatalError("Error loading persistent store: \(error)")
            }
        })
        return container
    }()
    
    private init() {
        fetchMensaDays()
    }
    
    func fetchMensaDays() {
        let request: NSFetchRequest<MensaDay> = MensaDay.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "date", ascending: false)]
        
        do {
            let fetchedDays = try persistentContainer.viewContext.fetch(request)
            DispatchQueue.main.async {
                self.mensaDays = fetchedDays
            }
        } catch {
            print("@CoreDataStack: Failed to fetch MensaDays: \(error.localizedDescription)")
        }
    }
    
    func save() {
        guard persistentContainer.viewContext.hasChanges else { return }
        
        do {
            try persistentContainer.viewContext.save()
        } catch {
            print("@CoreDataStack: Failed to save: \(error.localizedDescription)")
        }
    }
    
    func add(mealResponse: MealResponse) {
        let newMensaDay = MensaDay(context: persistentContainer.viewContext)
        newMensaDay.id = UUID()
        newMensaDay.date = Date()
        newMensaDay.funny_title = mealResponse.funny_title
        newMensaDay.comment = mealResponse.comment
        mealResponse.meals.map {
            let newMeal = Meal(context: persistentContainer.viewContext)
            newMeal.id = UUID()
            
            newMeal.title = $0.title
            newMeal.explanation = $0.explanation
            newMeal.price = $0.price
            return newMeal
        }.forEach {
            newMensaDay.addToMeals($0)
        }
    
        save()
        
        DispatchQueue.main.async {
            self.mensaDays.insert(newMensaDay, at: 0)
        }
    }
    
    func delete(mensaDay: MensaDay) {
        persistentContainer.viewContext.delete(mensaDay)
        save()
    }
}
