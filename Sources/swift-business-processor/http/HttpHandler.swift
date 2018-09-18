//
//  HttpHandler.swift
//
//  Created by Ben Pinhorn on 2018-09-08.
//

import Foundation

import Foundation
import NIO
import NIOHTTP1

struct SimpleResponseBody: Codable {
    var message: String = ""
}

public class HttpHandler: ChannelInboundHandler {
    
    public typealias InboundIn = HTTPServerRequestPart
    public typealias OutboundOut = HTTPServerResponsePart
    
    private var requestData: RequestData = RequestData()
    private var state: ReadState = ReadState.notProcessing
    
    enum HttpHandlerError: Error {
        case RequestPartsInWrongOrder
        case InvalidPathInRequestHeader
        case UnsupportedKeepAliveSettingReceived
        case NoPathHandlerForPathInRequestHeader
        case NoMethodReceivedInRequestHeader
        case NoBodyOnBodiedRequest
    }
    
    private struct RequestData {
        var requestVersion: HTTPVersion?
        var requestPath: URL?
        var requestMethod: HTTPMethod?
        var pathHandler: ((Data) -> Void)?
        var requestBody: ByteBuffer?
    }
    
    public enum ReadState {
        
        case notProcessing
        case waitingForBody
        case fullMessageReceived
        
        mutating func headerReceivedAndValidated() throws {
            if self == .notProcessing {
                self = .waitingForBody
                print("HTTP headers received and validated.")
            } else {
                print("Headers received and validated in wrong order.")
                throw HttpHandlerError.RequestPartsInWrongOrder
            }
        }
        
        mutating func bodyReceivedAndValidated() throws {
            if self == .waitingForBody {
                self = .fullMessageReceived
                print("Full HTTP message received and validated.")
            } else {
                print("Body received and validated in wrong order.")
                throw HttpHandlerError.RequestPartsInWrongOrder
            }
        }
        
        mutating func responseSent() throws {
             self = .notProcessing
        }
        
        mutating func reset() {
            self = .notProcessing
        }
    }
    
    
    public func channelRead(ctx: ChannelHandlerContext, data: NIOAny) {
        let reqPart: HTTPServerRequestPart = unwrapInboundIn(data)
        
        switch reqPart {
        case .head(let header):
            
            do {
                try validate(header: header)
                
                do {
                    try state.headerReceivedAndValidated()
                } catch HttpHandlerError.RequestPartsInWrongOrder {
                    sendErrorResponse(context: ctx, status: .internalServerError, message: "State error in HTTP Handler")
                } catch {
                    fatalError("Unknown error in HTTP handler state.")
                }
            } catch HttpHandlerError.InvalidPathInRequestHeader {
                sendErrorResponse(context: ctx, status: .notFound, message: "Path was malformed.")
            } catch HttpHandlerError.NoMethodReceivedInRequestHeader {
                sendErrorResponse(context: ctx, status: .badRequest, message: "No method received.")
            } catch HttpHandlerError.NoPathHandlerForPathInRequestHeader {
                sendErrorResponse(context: ctx, status: .badRequest, message: "No handler for path.")
            } catch HttpHandlerError.UnsupportedKeepAliveSettingReceived {
                sendErrorResponse(context: ctx, status: .badRequest, message: "Keep Alive connections not allowed.")
            } catch {
                fatalError("Unknown error in validaing HTTP header.")
            }
            
            
            
        case .body(let body):
            
            do {
                try validate(body: body)
                
                //this is where the event interface starts
                
                guard let path = requestData.requestPath else {
                    sendErrorResponse(context: ctx, status: .internalServerError, message: "State error in HTTP Handler")
                    return
                }
                
                guard let handle = BusinessProcessor.pathHandlerRegistry.retrieve(key: path) else {
                    sendErrorResponse(context: ctx, status: .internalServerError, message: "State error in HTTP Handler")
                    return
                }
                
                guard var body = requestData.requestBody else {
                    sendErrorResponse(context: ctx, status: .internalServerError, message: "State error in HTTP Handler")
                    return
                }
                
                let bodyString = body.readString(length: body.readableBytes)
                
                guard let bodyData = bodyString?.data(using: .utf8) else {
                    sendErrorResponse(context: ctx, status: .badRequest, message: "Unparseable body received.")
                    return
                }
                
                handle(bodyData)
                
                do {
                    try state.bodyReceivedAndValidated()
                } catch HttpHandlerError.RequestPartsInWrongOrder {
                    sendErrorResponse(context: ctx, status: .internalServerError, message: "State error in HTTP Handler")
                } catch {
                    fatalError("Unknown error in HTTP handler state.")
                }
            } catch HttpHandlerError.NoBodyOnBodiedRequest {
                sendErrorResponse(context: ctx, status: .badRequest, message: "No body received.")
            } catch {
                fatalError("Unknown error validating HTTP body.")
            }
            
        case .end:
            
            let returnVersion = HTTPVersion(major: 1, minor: 1)
            
            switch state {
                
            case .fullMessageReceived:
                
                let returnHead = HTTPResponseHead(version: returnVersion,
                                                  status: .ok)
                sendResponse(context: ctx, headers: returnHead, body: SimpleResponseBody(message: "Request received and processed."))
                
            default:
                
                print("Something went wrong in HTTP handler.")
                sendErrorResponse(context: ctx, status: .internalServerError, message: "Unknown error in HTTP handler.")
            }
        }
    }
    
    //TODO: change this function, it does two things
    private func validate(header: HTTPRequestHead) throws {
        
        guard let path = URL(string: header.uri) else {
            throw HttpHandlerError.InvalidPathInRequestHeader
        }
        
        guard let pathHandler = BusinessProcessor.pathHandlerRegistry.retrieve(key: path) else {
            throw HttpHandlerError.NoPathHandlerForPathInRequestHeader
        }
        
        requestData.requestMethod = header.method
        requestData.requestPath = URL(string: header.uri)
        requestData.requestVersion = header.version
        requestData.pathHandler = pathHandler
        
    }

    private func validate(body: ByteBuffer) throws {

        guard let requestMethod = requestData.requestMethod else {
            throw HttpHandlerError.NoMethodReceivedInRequestHeader
        }
        
        switch requestMethod {
            
        case .GET: return
        default:
            
            if body.writerIndex == 0 {
                throw HttpHandlerError.NoBodyOnBodiedRequest
            }
            
            requestData.requestBody = body
            
        }
    }
    
    private func sendErrorResponse(context: ChannelHandlerContext, status: HTTPResponseStatus, message: String) {
        
        let returnVersion = HTTPVersion(major: 1, minor: 1)
        
        let returnHead = HTTPResponseHead(version: returnVersion, status: status)
        
        sendResponse(context: context, headers: returnHead, body: SimpleResponseBody(message: message))
        
    }
    
    private func sendResponse<Body: Codable>(context: ChannelHandlerContext, headers: HTTPResponseHead, body: Body) {
        
        defer {
            cleanUp()
        }
        
        let returnHeadPart = HTTPServerResponsePart.head(headers)
        
        let encoder = JSONEncoder()
        
        do {
            
            let bodyAsJSON = try encoder.encode(body)
            
            var buffer = context.channel.allocator.buffer(capacity: 42)
            buffer.write(string: String(data: bodyAsJSON, encoding: .utf8)!)
            let returnBodyPart = HTTPServerResponsePart.body(.byteBuffer(buffer))
            
            
            let returnEndPart = HTTPServerResponsePart.end(nil)
            
            _ = context.channel.write(returnHeadPart)
            _ = context.channel.write(returnBodyPart)
            _ = context.channel.writeAndFlush(returnEndPart).then {
                context.channel.close()
            }
            
            do {
                try state.responseSent()
            } catch HttpHandlerError.RequestPartsInWrongOrder {
                sendErrorResponse(context: context, status: .internalServerError, message: "State error in HTTP Handler")
            } catch {
                fatalError("Unknown error in HTTP handler state.")
            }
        } catch {
            print("Response body could not be encoded.")
            
            sendErrorResponse(context: context, status: .internalServerError, message: "Error encoding response body.")
        }
    }
    
    private func cleanUp() {
        
        if state != .notProcessing {
            state.reset() //resets to correct state
        }
        
        requestData = RequestData()
        
    }
    
    public func getState() -> ReadState {
        return self.state
    }
}






