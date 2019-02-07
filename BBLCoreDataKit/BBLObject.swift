//
//  BBLObject.swift
//  BBLCoreDataKit
//
//  Created by Joel Perry on 2/26/16.
//  Copyright © 2016 Joel Perry. All rights reserved.
//

import Foundation
import CoreData

open class BBLObject: NSManagedObject {
  
  @NSManaged public var idString: String
  
  open func touchRelationships() {
    entity.relationshipsByName.forEach { (key, relationship) in
      if let inverse = relationship.inverseRelationship {
        switch relationship.isToMany {
        case true:
          guard let set = self.value(forKey: relationship.name) as? Set<BBLObject> else { return }
          set.forEach {
            $0.willChangeValue(forKey: inverse.name)
            $0.didChangeValue(forKey: inverse.name)
          }
          
        case false:
          guard let object = self.value(forKey: relationship.name) as? BBLObject else { return }
          object.willChangeValue(forKey: inverse.name)
          object.didChangeValue(forKey: inverse.name)
        }
      }
    }
  }
  
  // MARK: - KVO
  private var kvoContext = 0
  private var kvoHandlers = [String : (new: Any?, old: Any?) -> Void]()
  private var observedKeys = Set<String>()
  private func isObserving(_ key: String) -> Bool { return observedKeys.contains(key) }
  
  open func addKvoHandler(forKey key: String,
                          handler: @escaping (_ new: Any?, _ old: Any?) -> Void) {
    kvoHandlers[key] = handler
  }
  
  open func removeKvoHandler(forKey key: String) {
    if isObserving(key) { removeObserver(self, forKeyPath: key, context: &kvoContext) }
    kvoHandlers.removeValue(forKey: key)
  }
  
  override open func awakeFromFetch() {
    kvoHandlers.forEach {
      if !isObserving($0.key) {
        addObserver(self, forKeyPath: $0.key, options: [ .new, .old ], context: &kvoContext)
        observedKeys.insert($0.key)
      }
    }
  }
  
  override open func awakeFromInsert() {
    kvoHandlers.forEach {
      if !isObserving($0.key) {
        addObserver(self, forKeyPath: $0.key, options: [ .new, .old ], context: &kvoContext)
        observedKeys.insert($0.key)
      }
    }
  }
  
  override open func prepareForDeletion() {
    kvoHandlers.forEach {
      if isObserving($0.key) {
        removeObserver(self, forKeyPath: $0.key, context: &kvoContext)
        observedKeys.remove($0.key)
      }
    }
    kvoHandlers.removeAll()
  }
  
  override open func willTurnIntoFault() {
    kvoHandlers.forEach {
      if isObserving($0.key) {
        removeObserver(self, forKeyPath: $0.key, context: &kvoContext)
        observedKeys.remove($0.key)
      }
    }
  }
  
  override open func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
    guard context == &kvoContext else {
      super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
      return
    }
    
    guard let keyPath = keyPath, let handler = kvoHandlers[keyPath] else { return }
    handler(change?[.newKey], change?[.oldKey])
  }
}
