//
//  HttpInputEvent.swift
//
//  Created by Ben Pinhorn on 2018-09-18.
//

import Foundation

/**
 
 Abstract class for an event which originated as an HttpRequest. Extend this class for easier reuse of HTTP body decoding.
 
 DO NOT DISPATCH AN OBJECT OF THIS TYPE FOR PROCESSING.
 
 */
class HttpInputEvent<T: Decodable>: Event {
    
    /**
     Type to deserialize body to.
     */
    typealias DataType = T
    
    /**
     Unique identifier for event, to be used for storage and retrieval, as well as logging for auditing purposes.
    */
    var eventID: UUID
    
    /**
     Data inside of event to be used by the `process()` function for determining business logic to run.
     */
    var eventData: T
    
    init(eventID: UUID = UUID(), rawHttpBody: Data) throws {
        
        let decoder = JSONDecoder()
        
        self.eventID = eventID
        
        let eventData = try decoder.decode(T.self, from: rawHttpBody)
        self.eventData = eventData
    }
    
    /**
     Process the event, by performing business logic on the eventData.
     
     DO NOT DIRECTLY CALL THIS FUNCTION, IT WILL `fatalError()`
     */
    func process() {
        fatalError("This is an abstract event, it should not be processed directly.")
    }
    
    
    
    
    
    
    
    
    
}
