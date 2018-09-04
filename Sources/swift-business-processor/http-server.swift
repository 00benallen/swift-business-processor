//
//  http-server.swift
//  swift-business-processor
//
//  Created by Ben Pinhorn on 2018-09-02.
//

import Foundation

enum HttpError: Error {
    case VersionNotFoundOrRecognized(String)
    case UnparsableMessage(String)
    case MalformedHeaderLine(String)
    case ContentTypeNotSupportedOrRecognized(String)
    case BodyNotDecodable(String)
    case MethodNotSupportedOrRecognized(String)
    case StatusCodeNotSupportedOrRecognized(String)
    case ServerStreamsCouldNotBeInitialized(String)
}

enum SupportedContentTypes: String {
    case JSON = "application/json; charset=utf-8"
}

class HttpMessage<T> where T: Encodable,  T: Decodable {
    
    enum HttpVersion: String {
        case One = "HTTP/1.0"
        case OnePointOne = "HTTP/1.1"
        case Two = "HTTP/2.0"
    }
    
    var version: HttpVersion
    
    var headers: [String: String]
    
    var bodyContentType: SupportedContentTypes?
    var body: T?
    
    init(version: HttpVersion, headers: [String: String], body: T?) {
        self.version = version
        self.headers = headers
        self.body = body
    }
    
    init(fullMessage: String) throws {
        
        //Split the message line by line
        let lines: [Substring] = fullMessage.split(separator: "\n")
        
        //Split the first line token by token
        let tokens: [Substring] = lines[0].split(separator: " ")
        
        var parsedVersion = HttpVersion.One
        for token in tokens {
            
            if token.starts(with: "HTTP/") {
                
                guard let version = HttpVersion.init(rawValue: String(token)) else {
                    throw HttpError.VersionNotFoundOrRecognized("Version of HTTP message could not be determined.")
                }
                
                parsedVersion = version
                
            }
        }
        
        self.version = parsedVersion
        self.headers = [:]
        
        
        var bodyFound: Bool = false
        var lineStartIndex: String.Index = fullMessage.startIndex
        for i in 1..<lines.count {
            
            let line = lines[i]
            lineStartIndex = fullMessage.index(lineStartIndex, offsetBy: line.count+1)
            
            //Headers might start
            if !bodyFound {
                
                //Headers have ended or no headers
                if line.isEmpty {
                    bodyFound = true
                } else {
                    
                    let header = try parseHttpHeaderLine(headerLine: line)
                    
                    self.headers[header.key] = header.value
                    
                }
            
            //Parse body
            } else {
                
                let bodyString = fullMessage[lineStartIndex...]
                
                if bodyContentType == SupportedContentTypes.JSON {
                    
                    self.body = try self.parseHttpBodyAsJSON(bodyString: bodyString)
                    
                }
            }
        }
    }
    
    struct HttpHeader {
        var key: String
        var value: String
    }

    func parseHttpHeaderLine(headerLine: Substring) throws -> HttpHeader {
        var tokens: [Substring] = headerLine.split(separator: ":")
        
        if tokens.count != 2 {
            throw HttpError.MalformedHeaderLine("HTTP Header could not be parsed.")
        } else {
            
            tokens[1] = Substring(tokens[1].trimmingCharacters(in: [" "])) //remove unnecessary space
            
            return HttpHeader(key: String(tokens[0]), value: String(tokens[1]))
        }
    }
    
    func parseHttpBodyAsJSON(bodyString: Substring) throws -> T? {
        
        let decoder = JSONDecoder()
        
        guard let dataFromBodyString = bodyString.data(using: String.Encoding.utf8) else {
            throw HttpError.BodyNotDecodable("Attempted to decode body as JSON in UTF8 but the decoding failed.")
        }
        
        let body: T? = try decoder.decode(T.self, from: dataFromBodyString)
        
        return body
        
    }
}

class HttpRequest<T>: HttpMessage<T> where T: Encodable, T: Decodable {
    
    enum SupportedHttpMethod: String {
        case GET="GET"
        case POST="POST"
        case PUT="PUT"
        case DELETE="DELETE"
    }
    
    var method: SupportedHttpMethod
    
    var target: String
    
    var path: URL?
    
    init(version: HttpVersion, headers: [String: String], body: T?, method: SupportedHttpMethod, target: String, path: URL?) {
        
        self.method = method
        
        self.target = target
        
        super.init(version: version, headers: headers, body: body)
        
        self.path = URL(string: target)
    }
    
    override init(fullMessage: String) throws {
        
        //Split the message line by line
        let lines: [Substring] = fullMessage.split(separator: "\n")
        
        //Split the first line token by token
        let tokens: [Substring] = lines[0].split(separator: " ")
        
        guard let method = SupportedHttpMethod.init(rawValue: String(tokens[0])) else {
            throw HttpError.MethodNotSupportedOrRecognized("HTTP Method of request could not be found, or is not supported.")
        }
        
        self.method = method
        
        self.target = String(lines[1])
        
        self.path = URL(string: self.target)
        
        try super.init(fullMessage: fullMessage)
    }
}

class HttpResponse<T>: HttpMessage<T> where T: Encodable, T: Decodable {
    
    enum SupportedHttpResponseCodes: String {
        
        case OK = "200 OK"
        case InternalServerError = "500 Internal Server Error"
        case BadRequest = "400 Bad Request"
        case Unauthorized = "401 Unauthorized"
        case NoContent = "201 No Content"
        
    }
    
    let statusCode: SupportedHttpResponseCodes
    
    init(version: HttpVersion, headers: [String: String], body: T?, statusCode: SupportedHttpResponseCodes) {
        
        self.statusCode = statusCode
        
        super.init(version: version, headers: headers, body: body)
    }
    
    override init(fullMessage: String) throws {
        
        //Split the message line by line
        let lines: [Substring] = fullMessage.split(separator: "\n")
        
        //Split the first line token by token
        let tokens: [Substring] = lines[0].split(separator: " ")
        
        guard let statusCode = SupportedHttpResponseCodes.init(rawValue: String(tokens[1] + tokens[2])) else {
            throw HttpError.MethodNotSupportedOrRecognized("HTTP Method of request could not be found, or is not supported.")
        }
        
        self.statusCode = statusCode
        
        
        try super.init(fullMessage: fullMessage)
    }
    
}

class HttpMessageHandler<RequestBody, ResponseBody>
where RequestBody: Encodable, RequestBody: Decodable, ResponseBody: Encodable, ResponseBody: Decodable {
    
    typealias HttpHandlerFunction = (HttpRequest<RequestBody>) -> HttpResponse<ResponseBody>
    
    var handle: HttpHandlerFunction
    
    init(handle: @escaping HttpHandlerFunction) {
        
        self.handle = handle
        
    }
}

//import Darwin.C
//let zero = Int8(0)
//let transportLayerType = SOCK_STREAM // TCP
//let internetLayerProtocol = AF_INET // IPv4
//let sock = socket(internetLayerProtocol, Int32(transportLayerType), 0)
//let portNumber = UInt16(4000)
//let socklen = UInt8(socklen_t(MemoryLayout<sockaddr_in>.size))
//var serveraddr = sockaddr_in()
//serveraddr.sin_family = sa_family_t(AF_INET)
//serveraddr.sin_port = in_port_t((portNumber << 8) + (portNumber >> 8))
//serveraddr.sin_addr = in_addr(s_addr: in_addr_t(0))
//serveraddr.sin_zero = (zero, zero, zero, zero, zero, zero, zero, zero)
//withUnsafePointer(to: &serveraddr) { sockaddrInPtr in
//    let sockaddrPtr = UnsafeRawPointer(sockaddrInPtr).assumingMemoryBound(to: sockaddr.self)
//    bind(sock, sockaddrPtr, socklen_t(socklen))
//}
//listen(sock, 5)
//print("Server listening on port \(portNumber)")
//repeat {
//    let client = accept(sock, nil, nil)
//    let html = "<!DOCTYPE html><html><body style='text-align:center;'><h1>Hello from <a href='https://swift.org'>Swift</a> Web Server.</h1></body></html>"
//    let httpResponse: String = """
//    HTTP/1.1 200 OK
//    server: simple-swift-server
//    content-length: \(html.count)
//    \(html)
//    """
//    httpResponse.withCString { bytes in
//        send(client, bytes, Int(strlen(bytes)), 0)
//        close(client)
//    }
//} while sock > -1

import Darwin

class HttpServer {
    
}
