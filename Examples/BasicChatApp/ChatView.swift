import SwiftUI
import SecureProxySDK

struct ChatView: View {
    @StateObject private var manager = SecureProxyManager(
        proxyKey: "pk_your_proxy_key_here",
        secretKey: "sk_your_secret_key_here"
    )
    @State private var inputText = ""
    @State private var selectedModel = "gpt-4o"
    
    private let models = ["gpt-4o", "gpt-4o-mini", "claude-3-5-sonnet-20241022", "gemini-1.5-pro"]
    
    var body: some View {
        NavigationView {
            VStack {
                // Model Selector
                Picker("Model", selection: $selectedModel) {
                    ForEach(models, id: \.self) { model in
                        Text(model).tag(model)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()
                
                // Messages List
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 12) {
                            ForEach(Array(manager.messages.enumerated()), id: \.offset) { index, message in
                                MessageBubble(message: message)
                                    .id(index)
                            }
                            
                            if manager.isLoading {
                                HStack {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                    Text("AI is thinking...")
                                        .foregroundColor(.secondary)
                                        .font(.caption)
                                }
                                .padding()
                            }
                        }
                        .padding()
                    }
                    .onChange(of: manager.messages.count) { _ in
                        withAnimation {
                            proxy.scrollTo(manager.messages.count - 1, anchor: .bottom)
                        }
                    }
                }
                
                // Error Display
                if let error = manager.lastError {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.red)
                        Text(error.localizedDescription)
                            .foregroundColor(.red)
                            .font(.caption)
                        Spacer()
                        Button("Dismiss") {
                            manager.clearError()
                        }
                        .font(.caption)
                    }
                    .padding()
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(8)
                    .padding(.horizontal)
                }
                
                // Input Area
                HStack {
                    TextField("Type your message...", text: $inputText, axis: .vertical)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .lineLimit(1...4)
                    
                    Button(action: sendMessage) {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.title2)
                            .foregroundColor(inputText.isEmpty ? .gray : .blue)
                    }
                    .disabled(inputText.isEmpty || manager.isLoading)
                }
                .padding()
            }
            .navigationTitle("SecureProxy Chat")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Clear") {
                        manager.clearConversation()
                    }
                    .disabled(manager.messages.isEmpty)
                }
            }
        }
    }
    
    private func sendMessage() {
        guard !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        let messageText = inputText
        inputText = ""
        
        Task {
            await manager.sendMessage(messageText, model: selectedModel)
        }
    }
}

struct MessageBubble: View {
    let message: Message
    
    var body: some View {
        HStack {
            if message.role == "user" {
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(message.role.capitalized)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(contentText)
                    .padding(.vertical, 8)
                    .padding(.horizontal, 12)
                    .background(backgroundColor)
                    .foregroundColor(textColor)
                    .cornerRadius(16)
            }
            
            if message.role == "assistant" {
                Spacer()
            }
        }
        .frame(maxWidth: .infinity, alignment: message.role == "user" ? .trailing : .leading)
    }
    
    private var contentText: String {
        switch message.content {
        case .text(let text):
            return text
        case .multimodal(let parts):
            return parts.compactMap { part in
                switch part.type {
                case "text":
                    return part.text
                case "image_url":
                    return "[Image]"
                default:
                    return nil
                }
            }.joined(separator: " ")
        }
    }
    
    private var backgroundColor: Color {
        message.role == "user" ? .blue : .gray.opacity(0.2)
    }
    
    private var textColor: Color {
        message.role == "user" ? .white : .primary
    }
}

#Preview {
    ChatView()
}