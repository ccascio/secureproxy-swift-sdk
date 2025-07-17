// SecureProxySDK.swift
// Version: 1.0.0
// A lightweight Swift SDK for SecureProxy LLM API service

import Foundation
import SwiftUI

// MARK: - Public Types

public struct Message {
    public let role: String
    public let content: MessageContent
    
    public init(role: String, content: String) {
        self.role = role
        self.content = .text(content)
    }
    
    public init(role: String, content: MessageContent) {
        self.role = role
        self.content = content
    }
}

public enum MessageContent {
    case text(String)
    case multimodal([ContentPart])
    
    public struct ContentPart {
        public let type: String
        public let text: String?
        public let imageURL: URL?
        
        public static func text(_ text: String) -> ContentPart {
            ContentPart(type: "text", text: text, imageURL: nil)
        }
        
        public static func image(_ url: URL) -> ContentPart {
            ContentPart(type: "image_url", text: nil, imageURL: url)
        }
    }
}

public struct ChatResponse {
    public let id: String
    public let choices: [Choice]
    public let usage: Usage?
    
    public struct Choice {
        public let message: Message
        public let finishReason: String?
    }
    
    public struct Usage {
        public let promptTokens: Int
        public let completionTokens: Int
        public let totalTokens: Int
    }
}

public enum SecureProxyError: Error, LocalizedError {
    case invalidProxyKey
    case authenticationFailed
    case networkError(Error)
    case invalidResponse
    case tokenExpired
    case rateLimitExceeded
    
    public var errorDescription: String? {
        switch self {
        case .invalidProxyKey:
            return "Invalid proxy key provided"
        case .authenticationFailed:
            return "Authentication failed"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .invalidResponse:
            return "Invalid response from server"
        case .tokenExpired:
            return "Access token has expired"
        case .rateLimitExceeded:
            return "Rate limit exceeded"
        }
    }
}

// MARK: - Main SDK Class

public class SecureProxyClient {
    private let proxyKey: String
    private let baseURL: String
    private let urlSession: URLSession
    
    private var accessToken: String?
    private var tokenExpiry: Date = Date.distantPast
    
    public init(proxyKey: String, baseURL: String = "https://api.secureproxy.com") {
        self.proxyKey = proxyKey
        self.baseURL = baseURL
        self.urlSession = URLSession.shared
    }
    
    // MARK: - Public Methods
    
    public func chatCompletion(
        model: String,
        messages: [Message],
        maxTokens: Int? = nil,
        temperature: Double? = nil
    ) async throws -> ChatResponse {
        let token = try await getValidToken()
        
        var requestBody: [String: Any] = [
            "model": model,
            "messages": messages.map { message in
                [
                    "role": message.role,
                    "content": encodeContent(message.content)
                ]
            }
        ]
        
        if let maxTokens = maxTokens {
            requestBody["max_tokens"] = maxTokens
        }
        
        if let temperature = temperature {
            requestBody["temperature"] = temperature
        }
        
        let url = URL(string: "\(baseURL)/api/v1/chat/completions")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        let (data, response) = try await urlSession.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw SecureProxyError.invalidResponse
        }
        
        switch httpResponse.statusCode {
        case 200:
            return try parseChatResponse(data)
        case 401:
            // Clear token and retry once
            accessToken = nil
            throw SecureProxyError.tokenExpired
        case 429:
            throw SecureProxyError.rateLimitExceeded
        default:
            throw SecureProxyError.networkError(
                NSError(domain: "SecureProxy", code: httpResponse.statusCode, userInfo: nil)
            )
        }
    }
    
    public func complete(_ prompt: String, model: String = "gpt-4o") async throws -> String {
        let messages = [Message(role: "user", content: prompt)]
        let response = try await chatCompletion(model: model, messages: messages)
        
        guard let firstChoice = response.choices.first,
              case .text(let content) = firstChoice.message.content else {
            throw SecureProxyError.invalidResponse
        }
        
        return content
    }
    
    public func vision(
        prompt: String,
        imageURL: URL,
        model: String = "gpt-4o"
    ) async throws -> String {
        let content = MessageContent.multimodal([
            .text(prompt),
            .image(imageURL)
        ])
        
        let messages = [Message(role: "user", content: content)]
        let response = try await chatCompletion(model: model, messages: messages)
        
        guard let firstChoice = response.choices.first,
              case .text(let content) = firstChoice.message.content else {
            throw SecureProxyError.invalidResponse
        }
        
        return content
    }
}

// MARK: - Private Methods

private extension SecureProxyClient {
    func getValidToken() async throws -> String {
        // Return existing token if still valid (with 5-minute buffer)
        if let token = accessToken, tokenExpiry.timeIntervalSinceNow > 300 {
            return token
        }
        
        // Request new token
        let url = URL(string: "\(baseURL)/api/auth/token")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let requestBody = ["proxyKey": proxyKey]
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        let (data, response) = try await urlSession.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw SecureProxyError.authenticationFailed
        }
        
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let token = json["token"] as? String,
              let expiresIn = json["expiresIn"] as? TimeInterval else {
            throw SecureProxyError.invalidResponse
        }
        
        accessToken = token
        tokenExpiry = Date().addingTimeInterval(expiresIn)
        
        return token
    }
    
    func encodeContent(_ content: MessageContent) -> Any {
        switch content {
        case .text(let text):
            return text
        case .multimodal(let parts):
            return parts.map { part in
                switch part.type {
                case "text":
                    return ["type": "text", "text": part.text ?? ""]
                case "image_url":
                    return [
                        "type": "image_url",
                        "image_url": ["url": part.imageURL?.absoluteString ?? ""]
                    ]
                default:
                    return ["type": part.type]
                }
            }
        }
    }
    
    func parseChatResponse(_ data: Data) throws -> ChatResponse {
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let id = json["id"] as? String,
              let choicesArray = json["choices"] as? [[String: Any]] else {
            throw SecureProxyError.invalidResponse
        }
        
        let choices = try choicesArray.map { choice in
            guard let messageDict = choice["message"] as? [String: Any],
                  let role = messageDict["role"] as? String,
                  let content = messageDict["content"] as? String else {
                throw SecureProxyError.invalidResponse
            }
            
            let message = Message(role: role, content: content)
            let finishReason = choice["finish_reason"] as? String
            
            return ChatResponse.Choice(message: message, finishReason: finishReason)
        }
        
        var usage: ChatResponse.Usage?
        if let usageDict = json["usage"] as? [String: Any],
           let promptTokens = usageDict["prompt_tokens"] as? Int,
           let completionTokens = usageDict["completion_tokens"] as? Int,
           let totalTokens = usageDict["total_tokens"] as? Int {
            usage = ChatResponse.Usage(
                promptTokens: promptTokens,
                completionTokens: completionTokens,
                totalTokens: totalTokens
            )
        }
        
        return ChatResponse(id: id, choices: choices, usage: usage)
    }
}

// MARK: - SwiftUI Integration

@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
@MainActor
public class SecureProxyManager: ObservableObject {
    private let client: SecureProxyClient
    
    @Published public var isLoading = false
    @Published public var lastError: SecureProxyError?
    @Published public var messages: [Message] = []
    @Published public var currentResponse = ""
    
    public init(proxyKey: String, baseURL: String = "https://api.secureproxy.com") {
        self.client = SecureProxyClient(proxyKey: proxyKey, baseURL: baseURL)
    }
    
    public func sendMessage(_ content: String, model: String = "gpt-4o") async {
        guard !isLoading else { return }
        
        isLoading = true
        lastError = nil
        
        let userMessage = Message(role: "user", content: content)
        messages.append(userMessage)
        
        do {
            let response = try await client.chatCompletion(
                model: model,
                messages: messages
            )
            
            if let assistantMessage = response.choices.first?.message {
                messages.append(assistantMessage)
                if case .text(let text) = assistantMessage.content {
                    currentResponse = text
                }
            }
        } catch let error as SecureProxyError {
            lastError = error
            messages.removeLast() // Remove the user message if failed
        } catch {
            lastError = .networkError(error)
            messages.removeLast() // Remove the user message if failed
        }
        
        isLoading = false
    }
    
    public func analyzeImage(prompt: String, imageURL: URL, model: String = "gpt-4o") async {
        guard !isLoading else { return }
        
        isLoading = true
        lastError = nil
        currentResponse = ""
        
        do {
            let response = try await client.vision(
                prompt: prompt,
                imageURL: imageURL,
                model: model
            )
            currentResponse = response
        } catch let error as SecureProxyError {
            lastError = error
        } catch {
            lastError = .networkError(error)
        }
        
        isLoading = false
    }
    
    public func clearConversation() {
        messages.removeAll()
        currentResponse = ""
        lastError = nil
    }
    
    public func clearError() {
        lastError = nil
    }
}
