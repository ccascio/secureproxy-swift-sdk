# SecureProxy Swift SDK

[![Swift](https://img.shields.io/badge/Swift-5.7+-orange.svg)](https://swift.org)
[![Platform](https://img.shields.io/badge/Platform-iOS%2013.0+%20|%20macOS%2010.15+-lightgrey.svg)](https://developer.apple.com)
[![License](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
!!!DO NOT USE UNTIL THIS MESSAGE IS CANCELLED!!!
A lightweight, secure Swift SDK for accessing LLM APIs (OpenAI, Anthropic, Google AI, etc.) without exposing your API keys in client applications.

## 🔐 Why SecureProxy?

**The Problem**: Embedding LLM API keys directly in mobile apps is a major security risk:
- ❌ API keys are exposed in app binaries and can be extracted
- ❌ Keys can be intercepted through network traffic analysis  
- ❌ No usage control or monitoring per user/device
- ❌ Billing abuse if keys are compromised

**The Solution**: SecureProxy acts as a secure intermediary with **Split-Key Security**:
- ✅ Your real API keys stay safe on our servers
- ✅ **Split-key authentication**: API key split into two halves for enhanced security
- ✅ **HMAC request signing**: All requests cryptographically signed to prevent tampering
- ✅ JWT-based authentication with automatic token refresh
- ✅ AES-256 encrypted storage of your LLM provider keys
- ✅ Rate limiting and usage monitoring per project
- ✅ Support for multiple LLM providers through one unified API

## 🚀 Quick Start

### Installation

#### Swift Package Manager (Recommended)
Add SecureProxy to your Xcode project:

1. **File** → **Add Package Dependencies**
2. Enter package URL: `https://github.com/ccascio/secureproxy-swift-sdk`
3. Select version and add to target

#### Manual Installation
Download `SecureProxySDK.swift` and add it to your Xcode project.

### Basic Usage

```swift
import SecureProxySDK

// Initialize with split-key authentication for enhanced security
let client = SecureProxyClient(
    proxyKey: "pk_your_proxy_key_here",    // First half of split key
    secretKey: "sk_your_secret_key_here"   // Second half for HMAC signing
)

// Simple text completion
let response = try await client.complete("Explain quantum computing in simple terms")
print(response)

// Chat conversation with context
let messages = [
    Message(role: "system", content: "You are a helpful assistant."),
    Message(role: "user", content: "What's the weather like in Tokyo?")
]
let chatResponse = try await client.chatCompletion(model: "gpt-4o", messages: messages)

// Image analysis (multimodal)
let imageURL = URL(string: "https://example.com/image.jpg")!
let analysis = try await client.vision(
    prompt: "What's in this image?", 
    imageURL: imageURL,
    model: "gpt-4o"
)
```

## 📱 SwiftUI Integration

```swift
import SwiftUI
import SecureProxySDK

struct ChatView: View {
    @State private var inputText = ""
    @State private var response = ""
    @State private var isLoading = false
    
    private let client = SecureProxyClient(
        proxyKey: "pk_your_proxy_key_here",
        secretKey: "sk_your_secret_key_here"
    )
    
    var body: some View {
        VStack {
            Text(response)
                .padding()
            
            HStack {
                TextField("Ask anything...", text: $inputText)
                
                Button("Send") {
                    Task {
                        isLoading = true
                        do {
                            response = try await client.complete(inputText)
                        } catch {
                            response = "Error: \(error.localizedDescription)"
                        }
                        isLoading = false
                    }
                }
                .disabled(isLoading)
            }
            .padding()
        }
    }
}
```

## 🎯 Supported Models

The SDK works with major LLM providers through SecureProxy:

| Provider | Example Models | Capabilities |
|----------|----------------|--------------|
| **OpenAI** | `gpt-4o`, `gpt-4o-mini`, `o1-preview` | Text, Vision, Code |
| **Anthropic** | `claude-3-5-sonnet-20241022`, `claude-3-haiku-20240307` | Text, Analysis |
| **Google AI** | `gemini-1.5-pro`, `gemini-1.5-flash` | Text, Vision, Code |
| **Cohere** | `command-r-plus`, `command-r` | Text, Chat |
| **100+ more LLMs** | ... | ... |

> **Note**: You configure which providers to use in your SecureProxy dashboard, not in the SDK.

## 🔧 Advanced Usage

### Error Handling

```swift
do {
    let response = try await client.complete("Hello world")
    print(response)
} catch SecureProxyError.rateLimitExceeded {
    print("Rate limit exceeded. Please try again later.")
} catch SecureProxyError.tokenExpired {
    print("Session expired. The SDK will automatically refresh.")
} catch SecureProxyError.authenticationFailed {
    print("Invalid proxy key. Check your credentials.")
} catch {
    print("Unexpected error: \(error)")
}
```

### Custom Parameters

```swift
let response = try await client.chatCompletion(
    model: "gpt-4o",
    messages: messages,
    maxTokens: 150,        // Limit response length
    temperature: 0.7       // Control randomness (0.0 - 1.0)
)
```

### Multi-turn Conversations

```swift
var conversation: [Message] = [
    Message(role: "system", content: "You are a helpful coding assistant.")
]

// Add user message
conversation.append(Message(role: "user", content: "How do I create a REST API in Swift?"))

// Get response
let response = try await client.chatCompletion(model: "gpt-4o", messages: conversation)

// Add assistant response to continue conversation
if let assistantMessage = response.choices.first {
    conversation.append(assistantMessage.message)
}
```

### Vision/Image Analysis

```swift
// From URL
let imageURL = URL(string: "https://example.com/product.jpg")!
let description = try await client.vision(
    prompt: "Describe this product and suggest marketing copy",
    imageURL: imageURL
)

// From local image (convert to base64 data URL)
let imageData = UIImage(named: "photo")?.jpegData(compressionQuality: 0.8)
let base64String = imageData?.base64EncodedString()
let dataURL = URL(string: "data:image/jpeg;base64,\(base64String!)")!

let analysis = try await client.vision(
    prompt: "What's happening in this photo?",
    imageURL: dataURL
)
```

## 🛡️ Security Features

### Split-Key Security Architecture
- **Proxy Key (1st half)**: Stored in client app, can be extracted but useless alone
- **Secret Key (2nd half)**: Used for HMAC signing, never transmitted to server
- **Complete Key**: Only exists temporarily on server during authentication

### Additional Security Layers
- **No API Key Exposure**: Your LLM provider keys never leave SecureProxy's secure servers
- **HMAC-SHA256 Signing**: All authentication requests cryptographically signed
- **JWT Authentication**: Short-lived tokens with automatic refresh
- **AES-256 Encryption**: All stored API keys are encrypted at rest
- **Timestamp Validation**: Prevents replay attacks with request timestamps
- **Rate Limiting**: Configurable limits per project and user
- **Domain Restrictions**: Optional IP/domain allowlisting for production apps

## 📊 Usage Monitoring

Track your API usage through the SecureProxy Dashboard:

- Real-time usage metrics and costs
- Per-model and per-provider breakdowns  
- Rate limit monitoring and alerts
- Historical usage analytics
- Project management

## 📚 API Reference

### SecureProxyClient

```swift
class SecureProxyClient {
    // Split-key authentication (recommended)
    init(proxyKey: String, secretKey: String, baseURL: String = "https://api.secureproxy.com")
    
    // Legacy authentication (deprecated)
    @available(*, deprecated, message: "Use init(proxyKey:secretKey:baseURL:) for enhanced security")
    init(proxyKey: String, baseURL: String = "https://api.secureproxy.com")
    
    func complete(_ prompt: String, model: String = "gpt-4o") async throws -> String
    
    func chatCompletion(
        model: String,
        messages: [Message],
        maxTokens: Int? = nil,
        temperature: Double? = nil
    ) async throws -> ChatResponse
    
    func vision(
        prompt: String,
        imageURL: URL,
        model: String = "gpt-4o"
    ) async throws -> String
}
```

### Message

```swift
struct Message {
    let role: String        // "system", "user", or "assistant"
    let content: MessageContent
    
    init(role: String, content: String)
    init(role: String, content: MessageContent)
}
```

### Error Types

```swift
enum SecureProxyError: Error {
    case invalidProxyKey
    case invalidSecretKey
    case authenticationFailed
    case networkError(Error)
    case invalidResponse
    case tokenExpired
    case rateLimitExceeded
    case hmacGenerationFailed
}
```

## 🔗 Getting Started

1. **Sign up** at [secure-token-proxy-ai.replit.app](https://secure-token-proxy-ai.replit.app)
2. **Add your LLM provider API keys** in the dashboard (OpenAI, Anthropic, etc.)
3. **Create a project** and get your split keys:
   - **Proxy Key** (`pk_...`): First half of the split key
   - **Secret Key** (`sk_...`): Second half used for HMAC signing
4. **Install this SDK** and start building with enhanced security!

## 📝 Examples

Check out the [Examples](Examples/) directory for complete sample projects:

- Basic Chat App - Simple SwiftUI chat interface
- Image Analysis App - Photo analysis with GPT-4 Vision
- Multi-Provider Demo - Switching between different LLM models

## 🤝 Support

- 🐛 [Issues & Bug Reports](https://github.com/ccascio/secureproxy-swift-sdk/issues)
- 📖 [Documentation](https://secure-token-proxy-ai.replit.app)

## 📄 License

This SDK is released under the MIT License. See [LICENSE](LICENSE) for details.

---

**Made with ❤️ by the SecureProxy team**

*Secure LLM API access for mobile and web applications*