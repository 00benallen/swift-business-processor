//
//  EventProtocls.swift
//  CNIOAtomics
//
//  Created by Ben Pinhorn on 2018-09-07.
//

import Foundation

public protocol Event {
    
    associatedtype DataType
    
    var uniqueEventId: String { get set }
    var eventData: DataType { get set }
    
}

protocol EventProducer {
    
    associatedtype EventType: Event
    
    var eventType: EventType { get set }
    
    func writeEvent(event: EventType)
    
}

protocol EventTransformer {
    
    associatedtype EventType: Event
    associatedtype Output
    
    func transformEvent(event: EventType) -> Output
    
}

protocol EventReader {
    
    associatedtype EventType: Event
    
    func readEvent(uniqueEventId: String) -> EventType
    
}
