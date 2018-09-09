//
//  EventManipulatorRegistry.swift
//
//  Created by Ben Pinhorn on 2018-09-08.
//

import Foundation

class EventManipulatorSet {
    
    let eventID: UUID
    let builder: EventBuilder?
    let writer: EventQueueWriter?
    let reader: EventQueueReader?
    let processor: EventProcessor?
    
    init(eventID: UUID, builder: EventBuilder?, writer: EventQueueWriter?, reader: EventQueueReader?, processor: EventProcessor?) {
        
        self.eventID = eventID
        self.builder = builder
        self.writer = writer
        self.reader = reader
        self.processor = processor
        
    }
    
}

class EventManipulatorRegistry {
    
    private var _registry: [EventManipulatorSet]
    
    var registry: [EventManipulatorSet] {
        get {
            return self._registry
        }
    }
    
    init() {
        
        self._registry = []
        
    }
    
    enum EventManipulatorRegistryError: Error {
        case EventManipulatorSetHasVariedEventIds
    }
    
    func register(set: EventManipulatorSet) throws {
        
        try validate(set: set)
        
        self._registry.append(set)
        
    }
    
    private func validate(set: EventManipulatorSet) throws {
        
        let eventID = set.eventID
        
        let builder = set.builder
        try validate(eventManipulator: builder, expectedEventID: eventID)
        
        let writer = set.writer
        try validate(eventManipulator: writer, expectedEventID: eventID)
        
        let reader = set.reader
        try validate(eventManipulator: reader, expectedEventID: eventID)
        
        let processor = set.processor
        try validate(eventManipulator: processor, expectedEventID: eventID)
    }
    
    private func validate(eventManipulator: EventManipulator?, expectedEventID: UUID) throws {
        
        if eventManipulator != nil {
            
            let eventManipulatorID = retrieveEventID(from: eventManipulator!)
            
            if expectedEventID != eventManipulatorID {
                throw EventManipulatorRegistryError.EventManipulatorSetHasVariedEventIds
            }
        }
    }
    
    private func retrieveEventID(from: EventManipulator) -> UUID {
        
        return type(of: from).manipulatableEventID
        
    }
    
}
