import AppKit
import Darwin
import Foundation
import SwiftUI

final class LocalTranscribeAppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApplication.shared.setActivationPolicy(.accessory)
    }
}

@main
struct MeetingNoteApp: App {
    @NSApplicationDelegateAdaptor(LocalTranscribeAppDelegate.self) private var appDelegate
    @StateObject private var appModel: AppModel

    init() {
        let isAudioSmokeTest = CommandLine.arguments.contains("--audio-smoke-test")
        let model = AppModel(prepareModelOnLaunch: !isAudioSmokeTest)
        _appModel = StateObject(wrappedValue: model)

        if CommandLine.arguments.contains("--mlx-smoke-test") {
            Task { @MainActor in
                do {
                    try await model.runMLXSmokeTest()
                    print("MLX smoke test passed")
                    Darwin.exit(EXIT_SUCCESS)
                } catch {
                    FileHandle.standardError.write(Data("MLX smoke test failed: \(error)\n".utf8))
                    Darwin.exit(EXIT_FAILURE)
                }
            }
        } else if CommandLine.arguments.contains("--audio-smoke-test") {
            Task { @MainActor in
                do {
                    try await model.runAudioCaptureSmokeTest()
                    print("Audio capture smoke test passed")
                    Darwin.exit(EXIT_SUCCESS)
                } catch {
                    FileHandle.standardError.write(Data("Audio capture smoke test failed: \(error)\n".utf8))
                    Darwin.exit(EXIT_FAILURE)
                }
            }
        }
    }

    var body: some Scene {
        MenuBarExtra {
            MenuBarView()
                .environmentObject(appModel)
        } label: {
            Label("Local Transcribe", systemImage: appModel.isRecording ? "waveform.circle.fill" : "waveform.circle")
        }
        .menuBarExtraStyle(.window)

        Window("Local Transcribe", id: "transcript") {
            TranscriptWindow()
                .environmentObject(appModel)
        }
        .defaultSize(width: 720, height: 560)

        Window("Local Transcribe Settings", id: "settings") {
            SettingsView()
                .environmentObject(appModel)
        }
        .defaultSize(width: 600, height: 680)
        .windowResizability(.contentSize)
    }
}
