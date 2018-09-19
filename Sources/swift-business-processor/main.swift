import Foundation

var pathHandlers:  [URL: (Data)->Void] = [:]

pathHandlers[URL(string: "/shutdown")!] = { data -> Void in
    
    do {
        
        let shutdownEvent = try ShutdownEvent(eventID: UUID.init(), eventData: data)
        
        BusinessProcessor.eventProcessingQueue.sync {
            shutdownEvent.process()
        }
        
        print("Shutdown event processed successfully.")
    } catch {
        print("Shutdown event data could not be decoded. Event will not be processed.")
    }
}

let config = BusinessProcessor.Configuration(httpServerPort: 8080, pathHandlers: pathHandlers)

try BusinessProcessor.start(config: config)

