//
//  BBLFetchedObjectController.swift
//  BBLCoreDataKit
//
//  Created by Joel Perry on 12/9/16.
//  Copyright © 2016 Joel Perry. All rights reserved.
//

import Foundation
import CoreData

public typealias FRC = NSFetchedResultsController<NSFetchRequestResult>
public typealias FetchedObjectHandler = (BBLObject, FRC) -> Void

public protocol BBLFetchedObjectController: NSFetchedResultsControllerDelegate {
    associatedtype ControllerStack: BBLStack
    
    var stack: ControllerStack { get }
    var controllers: [FRC] { get set }
    var objectsInProgress: [ Int : Set<String> ] { get set }
    var fetchedObjectHandlers: [ Int : FetchedObjectHandler ] { get set }
    
    init(_ stack: ControllerStack)
}

public extension BBLFetchedObjectController {
    
    // MARK: Managed Controllers
    func addManagedController(_ frc: FRC, fetchedObjectHandler: @escaping FetchedObjectHandler) {
        if !controllers.contains(frc) { controllers.append(frc) }
        if objectsInProgress[frc.hash] == nil { objectsInProgress[frc.hash] = Set<String>() }
        if fetchedObjectHandlers[frc.hash] == nil { fetchedObjectHandlers[frc.hash] = fetchedObjectHandler }
    }
    
    func removeManagedController(_ frc: FRC) {
        if let index = controllers.index(of: frc) { controllers.remove(at: index) }
        if objectsInProgress[frc.hash] != nil { objectsInProgress[frc.hash] = nil }
        if fetchedObjectHandlers[frc.hash] != nil { fetchedObjectHandlers[frc.hash] = nil }
    }
    
    func startManagedControllers() {
        stack.performBlock { [weak self] in
            self?.controllers.forEach { (controller) in
                controller.delegate = self
                controller.fetch("BBLFetchedObjectController.startManagedControllers()")
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
    
    // MARK: - Progress
    func setObjectId(_ idString: String, inProgress: Bool, onFetchedResultsController frc: FRC) {
        guard var progressSet = objectsInProgress[frc.hash] else { return }
        switch inProgress {
        case true: progressSet.insert(idString)
        case false: progressSet.remove(idString)
        }
        objectsInProgress[frc.hash] = progressSet
    }
    
    func objectIdIsInProgress(_ idString: String, onFetchedResultsController frc: FRC) -> Bool {
        guard let progressSet = objectsInProgress[frc.hash] else { return false }
        return progressSet.contains(idString)
    }
}
