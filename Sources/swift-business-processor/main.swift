import Foundation

var pathHandlers:  [URL: (Data)->Void] = [:]

pathHandlers[URL(string: "/shutdown")!] = { data -> Void in
    
    do {
        
        let shutdownEvent = try ShutdownEvent(eventID: UUID.init(), eventData: data)
        
        BusinessProcessor.eventProcessingQueue.async {
            shutdownEvent.process()
        }
        
        print("Shutdown event queued successfully w/ UUID: \(shutdownEvent.eventID).")
    } catch {
        print("Shutdown event could not be initialzied. Event will not be processed.")
    }
}

pathHandlers[URL(string: "/benchmark")!] = { data -> Void in
    
    do {
        
        let benchmarkEvent = try BenchmarkEvent(eventID: UUID.init(), rawHttpBody: data)
        
        BusinessProcessor.eventProcessingQueue.async {
            benchmarkEvent.process()
        }
        
        print("Benchmark event queued successfully w/ UUID: \(benchmarkEvent.eventID).")
    } catch {
        print("Benchmark event could not be initialized. Event will not be processed.")
    }
}

let config = BusinessProcessor.Configuration(httpServerPort: 8080, pathHandlers: pathHandlers)

try BusinessProcessor.start(config: config)

