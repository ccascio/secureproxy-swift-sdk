# Multi-Provider Demo Example

A SwiftUI app demonstrating how to use different LLM providers through the SecureProxy Swift SDK.

## Features

- Switch between different LLM providers and models
- Compare responses from different models
- Model performance metrics
- Provider-specific capabilities showcase
- Advanced parameter controls

## Setup

1. Replace `"pk_your_proxy_key_here"` with your actual proxy key
2. Configure your desired LLM providers in the SecureProxy dashboard
3. Run the app in Xcode
4. Compare different models!

## Key Components

- `MultiProviderView`: Main interface for provider comparison
- `ModelCard`: Individual model information display
- `ResponseComparison`: Side-by-side response comparison
- `SecureProxyManager`: Handles SDK integration with reactive state

## Supported Providers

- OpenAI (GPT-4, GPT-4o, GPT-4o-mini)
- Anthropic (Claude 3.5 Sonnet, Claude 3 Haiku)
- Google AI (Gemini 1.5 Pro, Gemini 1.5 Flash)
- Cohere (Command R+, Command R)