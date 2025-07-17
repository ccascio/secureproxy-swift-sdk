import SwiftUI
import PhotosUI
import SecureProxySDK

struct ImageAnalysisView: View {
    @StateObject private var manager = SecureProxyManager(
        proxyKey: "pk_your_proxy_key_here",
        secretKey: "sk_your_secret_key_here"
    )
    @State private var selectedImage: UIImage?
    @State private var imagePickerItem: PhotosPickerItem?
    @State private var prompt = "What's in this image?"
    @State private var selectedModel = "gpt-4o"
    @State private var imageURL = ""
    @State private var analysisMode: AnalysisMode = .photoLibrary
    
    private let visionModels = ["gpt-4o", "gpt-4o-mini", "gemini-1.5-pro", "gemini-1.5-flash"]
    
    enum AnalysisMode: String, CaseIterable {
        case photoLibrary = "Photo Library"
        case url = "URL"
        
        var systemImage: String {
            switch self {
            case .photoLibrary: return "photo.on.rectangle"
            case .url: return "link"
            }
        }
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Mode Selector
                    Picker("Analysis Mode", selection: $analysisMode) {
                        ForEach(AnalysisMode.allCases, id: \.self) { mode in
                            Label(mode.rawValue, systemImage: mode.systemImage)
                                .tag(mode)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding()
                    
                    // Image Selection
                    Group {
                        if analysisMode == .photoLibrary {
                            photoLibrarySection
                        } else {
                            urlSection
                        }
                    }
                    
                    // Model Selector
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Vision Model")
                            .font(.headline)
                        
                        Picker("Model", selection: $selectedModel) {
                            ForEach(visionModels, id: \.self) { model in
                                Text(model).tag(model)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(12)
                    .padding(.horizontal)
                    
                    // Prompt Input
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Analysis Prompt")
                            .font(.headline)
                        
                        TextField("What would you like to know about this image?", text: $prompt, axis: .vertical)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .lineLimit(2...4)
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(12)
                    .padding(.horizontal)
                    
                    // Analyze Button
                    Button(action: analyzeImage) {
                        HStack {
                            if manager.isLoading {
                                ProgressView()
                                    .scaleEffect(0.8)
                                Text("Analyzing...")
                            } else {
                                Image(systemName: "eye.fill")
                                Text("Analyze Image")
                            }
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(canAnalyze ? Color.blue : Color.gray)
                        .cornerRadius(12)
                    }
                    .disabled(!canAnalyze || manager.isLoading)
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
                    if !manager.currentResponse.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Analysis Result")
                                .font(.headline)
                            
                            Text(manager.currentResponse)
                                .padding()
                                .background(Color.green.opacity(0.1))
                                .cornerRadius(12)
                        }
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(12)
                        .padding(.horizontal)
                    }
                }
            }
            .navigationTitle("Image Analysis")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Clear") {
                        clearAll()
                    }
                    .disabled(manager.currentResponse.isEmpty && selectedImage == nil)
                }
            }
        }
        .onChange(of: imagePickerItem) { newItem in
            Task {
                if let data = try? await newItem?.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    selectedImage = image
                }
            }
        }
    }
    
    private var photoLibrarySection: some View {
        VStack(spacing: 16) {
            if let image = selectedImage {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxHeight: 200)
                    .cornerRadius(12)
            } else {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.gray.opacity(0.2))
                    .frame(height: 200)
                    .overlay(
                        VStack {
                            Image(systemName: "photo")
                                .font(.system(size: 40))
                                .foregroundColor(.gray)
                            Text("No image selected")
                                .foregroundColor(.gray)
                        }
                    )
            }
            
            PhotosPicker(selection: $imagePickerItem, matching: .images) {
                Label("Select from Photo Library", systemImage: "photo.on.rectangle")
                    .foregroundColor(.blue)
            }
        }
        .padding()
    }
    
    private var urlSection: some View {
        VStack(spacing: 16) {
            AsyncImage(url: URL(string: imageURL)) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxHeight: 200)
                    .cornerRadius(12)
            } placeholder: {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.gray.opacity(0.2))
                    .frame(height: 200)
                    .overlay(
                        VStack {
                            Image(systemName: "link")
                                .font(.system(size: 40))
                                .foregroundColor(.gray)
                            Text(imageURL.isEmpty ? "Enter image URL below" : "Loading...")
                                .foregroundColor(.gray)
                        }
                    )
            }
            
            TextField("Enter image URL", text: $imageURL)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .keyboardType(.URL)
                .autocapitalization(.none)
        }
        .padding()
    }
    
    private var canAnalyze: Bool {
        !prompt.isEmpty && (
            (analysisMode == .photoLibrary && selectedImage != nil) ||
            (analysisMode == .url && !imageURL.isEmpty && URL(string: imageURL) != nil)
        )
    }
    
    private func analyzeImage() {
        guard canAnalyze else { return }
        
        Task {
            if analysisMode == .photoLibrary {
                await analyzeSelectedImage()
            } else {
                await analyzeImageURL()
            }
        }
    }
    
    private func analyzeSelectedImage() async {
        guard let image = selectedImage,
              let imageData = image.jpegData(compressionQuality: 0.8) else { return }
        
        let base64String = imageData.base64EncodedString()
        let dataURL = URL(string: "data:image/jpeg;base64,\(base64String)")!
        
        await manager.analyzeImage(prompt: prompt, imageURL: dataURL, model: selectedModel)
    }
    
    private func analyzeImageURL() async {
        guard let url = URL(string: imageURL) else { return }
        
        await manager.analyzeImage(prompt: prompt, imageURL: url, model: selectedModel)
    }
    
    private func clearAll() {
        selectedImage = nil
        imagePickerItem = nil
        imageURL = ""
        manager.clearConversation()
    }
}

#Preview {
    ImageAnalysisView()
}