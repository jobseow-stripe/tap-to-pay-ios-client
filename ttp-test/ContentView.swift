// ContentView.swift
import SwiftUI
import StripeTerminal
import Combine

struct ContentView: View {
    @StateObject private var terminalManager = TerminalManager()

    var body: some View {
        VStack(spacing: 20) {
            Spacer()

            Text(terminalManager.statusMessage)
                .multilineTextAlignment(.center)
                .padding()

            // Reader selection list
            if !terminalManager.discoveredReaders.isEmpty && terminalManager.currentState == .discovering {
                List(terminalManager.discoveredReaders, id: \.serialNumber) { reader in
                    Button {
                        Task {
                            await terminalManager.selectReader(reader)
                        }
                    } label: {
                        VStack(alignment: .leading) {
                            Text(reader.label ?? reader.serialNumber)
                                .font(.headline)
                            Text(reader.serialNumber)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }

            Button(terminalManager.buttonTitle) {
                Task {
                    switch terminalManager.currentState {
                    case .initial:
                        await terminalManager.discoverReaders()
                    case .connected:
                        await terminalManager.collectPayment()
                    default:
                        break
                    }
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(terminalManager.isProcessing ||
                      terminalManager.currentState == .connecting ||
                      terminalManager.currentState == .discovering)

            if terminalManager.currentState == .connected {
                Button("Restart Payment Flow") {
                    Task {
                        await terminalManager.restart()
                    }
                }
                .buttonStyle(.bordered)
                .tint(.red)
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(uiColor: .systemGroupedBackground))
    }
}
