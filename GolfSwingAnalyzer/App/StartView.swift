import PhotosUI
import SwiftUI

struct StartView: View {
    @StateObject private var analysisViewModel = AnalysisViewModel()
    @State private var isRecording = false
    @State private var photosPickerItem: PhotosPickerItem?

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                statusOrActions
                if let errorMessage = analysisViewModel.errorMessage {
                    Text(errorMessage)
                        .font(.footnote)
                        .foregroundStyle(.red)
                        .multilineTextAlignment(.center)
                }
            }
            .padding()
            .navigationDestination(isPresented: $isRecording) {
                RecordSwingFlowView()
            }
            .onChange(of: photosPickerItem) { _, newItem in
                guard let newItem else { return }
                Task { await importAndAnalyze(newItem) }
            }
        }
    }

    @ViewBuilder
    private var statusOrActions: some View {
        if analysisViewModel.isAnalyzing {
            ProgressView("Analyzing swing…")
        } else if let session = analysisViewModel.session {
            VStack(spacing: 12) {
                Text("Analysis complete").font(.headline)
                Text("\(session.tips.count) tip(s) found — see Xcode console for details.")
                    .font(.footnote)
                    .multilineTextAlignment(.center)
                Button("Start Over") {
                    analysisViewModel.reset()
                    photosPickerItem = nil
                }
            }
        } else {
            Button("Record New Swing") { isRecording = true }
                .buttonStyle(.borderedProminent)

            PhotosPicker("Import from Library", selection: $photosPickerItem, matching: .videos)
                .buttonStyle(.bordered)
        }
    }

    private func importAndAnalyze(_ item: PhotosPickerItem) async {
        do {
            let url = try await VideoImporter.localURL(for: item)
            analysisViewModel.analyze(videoURL: url)
        } catch {
            analysisViewModel.errorMessage = "Couldn't import that video: \(error.localizedDescription)"
        }
    }
}
