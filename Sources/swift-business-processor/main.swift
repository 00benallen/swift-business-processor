import Foundation

var pathHandlers:  [URL: (Data)->Void] = [:]

pathHandlers[URL(string: "/shutdown")!] = { data -> Void in
   
    let decoder = JSONDecoder()
    
    do {
        let shutdownData = try decoder.decode(ShutdownEvent.ShutdownData.self, from: data)
        
        let shutdownEvent = ShutdownEvent(eventID: UUID.init(), eventData: shutdownData)
        
        shutdownEvent.process()
        
        print("Shutdown event processed successfully.")
    } catch {
        print("Shutdown event data could not be decoded. Event will not be processed.")
        return
    }
}

let config = BusinessProcessor.Configuration(httpServerPort: 8080, pathHandlers: pathHandlers)

try BusinessProcessor.start(config: config)

