# SecureProxy Swift SDK Examples

This directory contains complete example applications demonstrating how to use the SecureProxy Swift SDK in different scenarios.

## Available Examples

### 1. Basic Chat App
**Location**: `BasicChatApp/`

A simple chat interface showcasing:
- Real-time messaging with AI models
- Message history management
- Loading states and error handling
- Model switching
- SwiftUI best practices

**Key Files**:
- `ChatView.swift` - Main chat interface
- `README.md` - Setup instructions

### 2. Image Analysis App
**Location**: `ImageAnalysisApp/`

An image analysis application featuring:
- Photo picker integration
- URL-based image analysis
- Multiple vision model support
- Custom prompt input
- Result display with error handling

**Key Files**:
- `ImageAnalysisView.swift` - Main image analysis interface
- `README.md` - Setup instructions

### 3. Multi-Provider Demo
**Location**: `MultiProviderDemo/`

A comparison tool demonstrating:
- Side-by-side model comparison
- Provider-specific capabilities
- Parameter controls (temperature, max tokens)
- Performance metrics
- Advanced configuration options

**Key Files**:
- `MultiProviderView.swift` - Main comparison interface
- `README.md` - Setup instructions

## Getting Started

1. **Choose an example** that matches your use case
2. **Copy the relevant files** to your Xcode project
3. **Replace the proxy key** with your actual key from the SecureProxy dashboard
4. **Install the SecureProxy SDK** using Swift Package Manager
5. **Run and customize** as needed

## Common Setup Steps

All examples require:

1. **SDK Installation**:
   ```
   File → Add Package Dependencies
   https://github.com/ccascio/secureproxy-swift-sdk
   ```

2. **Proxy Key Configuration**:
   Replace `"pk_your_proxy_key_here"` with your actual proxy key

3. **Import the SDK**:
   ```swift
   import SecureProxySDK
   ```

## Features Demonstrated

- ✅ **SwiftUI Integration** - Modern declarative UI patterns
- ✅ **Reactive State Management** - ObservableObject and @Published
- ✅ **Error Handling** - Comprehensive error states
- ✅ **Loading States** - User feedback during API calls
- ✅ **Multi-Model Support** - Different LLM providers
- ✅ **Vision Capabilities** - Image analysis and understanding
- ✅ **Conversation Management** - Chat history and context
- ✅ **Parameter Controls** - Temperature, tokens, etc.

## Support

If you encounter issues with any example:
1. Check the example's README for specific setup instructions
2. Verify your proxy key is correct and active
3. Ensure your SecureProxy dashboard has the required LLM providers configured
4. Check the main SDK documentation for API reference

## Contributing

Feel free to contribute additional examples or improvements to existing ones!