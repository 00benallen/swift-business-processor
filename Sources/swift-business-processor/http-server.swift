//
//  http-server.swift
//  swift-business-processor
//
//  Created by Ben Pinhorn on 2018-09-02.
//

import Foundation

enum HttpError: Error {
    case VersionNotFound(String)
    case UnparsableMessage(String)
    case MalformedHeaderLine(String)
    case ContentTypeNotSupported(String)
    case BodyNotDecodable(String)
    case MethodNotSupportedOrFound(String)
}

enum SupportedContentTypes: String {
    case JSON = "application/json"
}

class HttpMessage<T: Decodable> {
    
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
                    throw HttpError.VersionNotFound("Version of HTTP message could not be determined.")
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

class HttpRequest<T: Decodable>: HttpMessage<T> {
    
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
            throw HttpError.MethodNotSupportedOrFound("HTTP Method of request could not be found, or is not supported.")
        }
        
        self.method = method
        
        self.target = String(lines[1])
        
        self.path = URL(string: self.target)
        
        try super.init(fullMessage: fullMessage)
    }
    
    
    
}

class HttpMessageHandler {
    
}
