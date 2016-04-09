# BBLCoreDataKit
BBLCoreDataKit is a Swift framework for quickly setting up Core Data implementations in your app.

## Overview

* BBLCoreDataKit is centered around the concept of a Stack, an object that adopts the BBLStack protocol. Each instance of a Stack encapsulates a persistence layer (in the form of a BBLPersistence class), a single NSManagedObjectContext, and collections of NSManagedObjects in that context.
* A Collection adopts the BBLCollection protocol and allows for the creation, management, and fetching of a single NSManagedObject subclass.
* NSManagedObject subclasses adopt the BBLObject protocol, which requires an `idString: String` property in order to uniquely identify each object instance.
* BBLPersistence is designed so that NSManagedObjectContexts share a single NSPersistentStoreCoordinator. Changes in one context are propagated to the others by the `mergeChangesFromContextDidSaveNotification` function.

## Sample Implementations
### Stack
```
final class MyStack: BBLStack {
    // MARK: - Required
    static var persistence: BBLPersistence = {
        let p = BBLPersistence(modelName: "MyModel")
        return p
    }()
    
    var context: NSManagedObjectContext!
    
    // MARK: - Stack Instances
    static var mainStack: MyStack = {
        let s = MyStack.init(concurrencyType: .MainQueueConcurrencyType)
        return s
    }()
    
    static var privateStack: MyStack = {
        let s = MyStack.init(concurrencyType: .PrivateQueueConcurrencyType)
        return s
    }()
    
    // MARK: - Object Collections
    lazy var myObjects: MyObjectCollection = {
        let c = MyObjectCollection(context: self.context)
        return c
    }()
}
```
* Set up shared persistence by providing (at a minimum) the name of your Core Data Model.
* Use static properties to hold your Stack instances, which you configure with a NSManagedObjectContextConcurrencyType.
* Use lazy variables to refer to Collections for each of your NSManagedObject subclasses.

### Collection
```
import Foundation
import BBLCoreDataKit

struct MyObjectCollection: BBLCollection {
    // MARK: - Required
    typealias Object = MyObject
    var context: NSManagedObjectContext!
    
    // MARK: - FetchedResultsControllers
    var allObjectsReversed: NSFetchedResultsController {
        return self.frc(sortKey: "idString", ascending: false)
    }
}
```
* Declare a `typealias` to indicate which NSManagedObject subclass the collection refers to.
* Use variables to define as many NSFetchedResultsController variations as you need. BBLCollection defines an `allObjects` property that returns a default NSFetchedResultsController.

### Object
```
import Foundation
import BBLCoreDataKit

class MyObject: NSManagedObject, BBLObject {
    
}
```
* In the NSManagedObject subclass, adopt the BBLObject protocol. This requires a conforming subclass to contain an `idString: String` property.

### Usage
```
let mainStack = MyStack.mainStack
let privateStack = MyStack.privateStack
        
privateStack.performBlockAndWait {
	for _ in 0..<10 {
   		let uuid = NSUUID()
    	_ = privateStack.myObjects.object(identifier: uuid)
    }
    privateStack.save("testMerge")
}
        
let frc = mainStack.myObjects.allObjects
frc.fetch("testMerge")
let objects = frc.fetchedObjects?.count
```
* Common context operations, such as `performBlock`, `performBlockAndWait`, and `save` can be called directly from the Stack instance.
* To aid in debugging, the `save` and `fetch` functions take a `site` parameter, which can be used to identify which call caused an error.
