//
//  EventProtocls.swift
//  CNIOAtomics
//
//  Created by Ben Pinhorn on 2018-09-07.
//

import Foundation

protocol Event {
    
    var uniqueEventId: String { get set }
    var eventData: Any { get set }
    
}

protocol EventWriter {
    
    associatedtype EventType: Event
    
    var eventType: EventType { get set }
    
    func writeEvent(event: Event)
    
}

protocol EventTransformer {
    
     associatedtype EventType: Event
    associatedtype Output
    
    func transformEvent(event: Event) -> Output
    
}
