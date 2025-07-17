import SwiftUI
import SecureProxySDK

struct MultiProviderView: View {
    @StateObject private var manager = SecureProxyManager(proxyKey: "pk_your_proxy_key_here")
    @State private var prompt = "Explain quantum computing in simple terms"
    @State private var selectedModels: Set<String> = ["gpt-4o", "claude-3-5-sonnet-20241022"]
    @State private var responses: [String: String] = [:]
    @State private var loadingModels: Set<String> = []
    @State private var temperature: Double = 0.7
    @State private var maxTokens: Int = 150
    
    private let modelGroups: [ModelGroup] = [
        ModelGroup(
            provider: "OpenAI",
            models: [
                ModelInfo(id: "gpt-4o", name: "GPT-4o", description: "Most capable model"),
                ModelInfo(id: "gpt-4o-mini", name: "GPT-4o Mini", description: "Faster, cost-effective"),
                ModelInfo(id: "o1-preview", name: "o1 Preview", description: "Advanced reasoning")
            ],
            color: .green
        ),
        ModelGroup(
            provider: "Anthropic",
            models: [
                ModelInfo(id: "claude-3-5-sonnet-20241022", name: "Claude 3.5 Sonnet", description: "Best for analysis"),
                ModelInfo(id: "claude-3-haiku-20240307", name: "Claude 3 Haiku", description: "Fast and efficient")
            ],
            color: .orange
        ),
        ModelGroup(
            provider: "Google AI",
            models: [
                ModelInfo(id: "gemini-1.5-pro", name: "Gemini 1.5 Pro", description: "Advanced capabilities"),
                ModelInfo(id: "gemini-1.5-flash", name: "Gemini 1.5 Flash", description: "Fast responses")
            ],
            color: .blue
        ),
        ModelGroup(
            provider: "Cohere",
            models: [
                ModelInfo(id: "command-r-plus", name: "Command R+", description: "Enhanced reasoning"),
                ModelInfo(id: "command-r", name: "Command R", description: "Reliable performance")
            ],
            color: .purple
        )
    ]
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Prompt Input
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Prompt")
                            .font(.headline)
                        
                        TextField("Enter your prompt to compare models", text: $prompt, axis: .vertical)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .lineLimit(3...6)
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(12)
                    .padding(.horizontal)
                    
                    // Parameter Controls
                    VStack(spacing: 16) {
                        Text("Parameters")
                            .font(.headline)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Temperature: \(temperature, specifier: "%.1f")")
                                Spacer()
                                Slider(value: $temperature, in: 0...1, step: 0.1)
                                    .frame(width: 150)
                            }
                            
                            HStack {
                                Text("Max Tokens: \(maxTokens)")
                                Spacer()
                                Slider(value: Binding(
                                    get: { Double(maxTokens) },
                                    set: { maxTokens = Int($0) }
                                ), in: 50...500, step: 50)
                                .frame(width: 150)
                            }
                        }
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(12)
                    .padding(.horizontal)
                    
                    // Model Selection
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Select Models to Compare")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        ForEach(modelGroups, id: \.provider) { group in
                            ModelGroupView(
                                group: group,
                                selectedModels: $selectedModels
                            )
                        }
                    }
                    
                    // Compare Button
                    Button(action: compareModels) {
                        HStack {
                            if !loadingModels.isEmpty {
                                ProgressView()
                                    .scaleEffect(0.8)
                                Text("Comparing \(loadingModels.count) models...")
                            } else {
                                Image(systemName: "arrow.triangle.2.circlepath")
                                Text("Compare Models")
                            }
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(canCompare ? Color.blue : Color.gray)
                        .cornerRadius(12)
                    }
                    .disabled(!canCompare || !loadingModels.isEmpty)
                    .padding(.horizontal)
                    
                    // Error Display
                    if let error = manager.lastError {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(.red)
                                Text("Error")
                                    .font(.headline)
                                    .foregroundColor(.red)
                                Spacer()
                                Button("Dismiss") {
                                    manager.clearError()
                                }
                                .font(.caption)
                            }
                            
                            Text(error.localizedDescription)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding()
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(12)
                        .padding(.horizontal)
                    }
                    
                    // Results
                    if !responses.isEmpty {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Comparison Results")
                                .font(.headline)
                                .padding(.horizontal)
                            
                            ForEach(Array(responses.keys.sorted()), id: \.self) { modelId in
                                if let response = responses[modelId],
                                   let modelInfo = findModelInfo(id: modelId) {
                                    ResponseCard(
                                        modelInfo: modelInfo,
                                        response: response,
                                        isLoading: loadingModels.contains(modelId)
                                    )
                                }
                            }
                        }
                    }
                }
                .padding(.bottom)
            }
            .navigationTitle("Model Comparison")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Clear") {
                        clearResults()
                    }
                    .disabled(responses.isEmpty)
                }
            }
        }
    }
    
    private var canCompare: Bool {
        !prompt.isEmpty && !selectedModels.isEmpty
    }
    
    private func compareModels() {
        guard canCompare else { return }
        
        responses.removeAll()
        loadingModels = selectedModels
        
        for modelId in selectedModels {
            Task {
                await testModel(modelId)
            }
        }
    }
    
    private func testModel(_ modelId: String) async {
        do {
            let messages = [Message(role: "user", content: prompt)]
            let response = try await SecureProxyClient(proxyKey: "pk_your_proxy_key_here")
                .chatCompletion(
                    model: modelId,
                    messages: messages,
                    maxTokens: maxTokens,
                    temperature: temperature
                )
            
            await MainActor.run {
                if let firstChoice = response.choices.first,
                   case .text(let content) = firstChoice.message.content {
                    responses[modelId] = content
                }
                loadingModels.remove(modelId)
            }
        } catch {
            await MainActor.run {
                responses[modelId] = "Error: \(error.localizedDescription)"
                loadingModels.remove(modelId)
            }
        }
    }
    
    private func findModelInfo(id: String) -> ModelInfo? {
        for group in modelGroups {
            if let model = group.models.first(where: { $0.id == id }) {
                return model
            }
        }
        return nil
    }
    
    private func clearResults() {
        responses.removeAll()
        loadingModels.removeAll()
        manager.clearError()
    }
}

struct ModelGroup {
    let provider: String
    let models: [ModelInfo]
    let color: Color
}

struct ModelInfo {
    let id: String
    let name: String
    let description: String
}

struct ModelGroupView: View {
    let group: ModelGroup
    @Binding var selectedModels: Set<String>
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(group.provider)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(group.color)
                .padding(.horizontal)
            
            ForEach(group.models, id: \.id) { model in
                HStack {
                    Image(systemName: selectedModels.contains(model.id) ? "checkmark.circle.fill" : "circle")
                        .foregroundColor(selectedModels.contains(model.id) ? group.color : .gray)
                        .onTapGesture {
                            toggleModel(model.id)
                        }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(model.name)
                            .font(.body)
                        Text(model.description)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                }
                .padding(.horizontal)
                .onTapGesture {
                    toggleModel(model.id)
                }
            }
        }
        .padding(.vertical, 8)
        .background(group.color.opacity(0.1))
        .cornerRadius(12)
        .padding(.horizontal)
    }
    
    private func toggleModel(_ modelId: String) {
        if selectedModels.contains(modelId) {
            selectedModels.remove(modelId)
        } else {
            selectedModels.insert(modelId)
        }
    }
}

struct ResponseCard: View {
    let modelInfo: ModelInfo
    let response: String
    let isLoading: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(modelInfo.name)
                        .font(.headline)
                    Text(modelInfo.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if isLoading {
                    ProgressView()
                        .scaleEffect(0.8)
                }
            }
            
            Divider()
            
            Text(response)
                .font(.body)
                .padding(.vertical, 4)
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
        .padding(.horizontal)
    }
}

#Preview {
    MultiProviderView()
}