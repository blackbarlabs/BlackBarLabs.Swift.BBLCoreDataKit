//
//  BBLFetchedObjectController.swift
//  BBLCoreDataKit
//
//  Created by Joel Perry on 12/9/16.
//  Copyright © 2016 Joel Perry. All rights reserved.
//

import Foundation
import CoreData

public typealias FetchedResultsController = NSFetchedResultsController<NSFetchRequestResult>
public typealias FetchedObjectHandler = (BBLObject, FetchedResultsController) -> Void

public protocol BBLFetchedObjectController: NSFetchedResultsControllerDelegate {
    associatedtype ControllerStack: BBLStack
    
    var stack: ControllerStack { get }
    var controllers: [FetchedResultsController] { get set }
    var objectsInProgress: [ Int : Set<String> ] { get set }
    var fetchedObjectHandlers: [ Int : FetchedObjectHandler ] { get set }
    
    init(_ stack: ControllerStack)
}

public extension BBLFetchedObjectController {
    func addManagedController(_ controller: FetchedResultsController,
                              withHandler handler: @escaping FetchedObjectHandler) {
        if !controllers.contains(controller) { controllers.append(controller) }
        if objectsInProgress[controller.hash] == nil { objectsInProgress[controller.hash] = Set<String>() }
        if fetchedObjectHandlers[controller.hash] == nil { fetchedObjectHandlers[controller.hash] = handler }
    }
    
    func removeManagedController(_ controller: FetchedResultsController) {
        if let index = controllers.firstIndex(of: controller) { controllers.remove(at: index) }
        if objectsInProgress[controller.hash] != nil { objectsInProgress[controller.hash] = nil }
        if fetchedObjectHandlers[controller.hash] != nil { fetchedObjectHandlers[controller.hash] = nil }
    }
    
    func startManagedControllers() {
        stack.performBlock { [weak self] in
            self?.controllers.forEach { (controller) in
                controller.delegate = self
                try? controller.performFetch()
                controller.fetchedObjects?.forEach { (object) in
                    self?.controller?(controller, didChange: object, at: nil, for: .insert, newIndexPath: nil)
                }
            }
        }
    }
    
    func stopManagedControllers() {
        stack.performBlock { [weak self] in
            self?.controllers.forEach {
                $0.delegate = nil
            }
        }
    }
    
    func clearManagedControllers() {
        stack.performBlock { [weak self] in
            self?.fetchedObjectHandlers.removeAll()
            self?.controllers.removeAll()
            self?.objectsInProgress.removeAll()
        }
    }
    
    // MARK: Progress
    func setObjectId(_ idString: String, inProgress: Bool,
                     onController controller: FetchedResultsController) {
        guard var progressSet = objectsInProgress[controller.hash] else { return }
        switch inProgress {
        case true: progressSet.insert(idString)
        case false: progressSet.remove(idString)
        }
        objectsInProgress[controller.hash] = progressSet
    }
    
    func objectIdIsInProgress(_ idString: String,
                              onController controller: FetchedResultsController) -> Bool {
        guard let progressSet = objectsInProgress[controller.hash] else { return false }
        return progressSet.contains(idString)
    }
}
