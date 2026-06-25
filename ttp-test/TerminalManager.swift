import SwiftUI
import StripeTerminal
import Combine

@MainActor
class TerminalManager: NSObject, ObservableObject {
    @Published var statusMessage = "Ready to connect"
    @Published var buttonTitle = "Discover Readers"
    @Published var isProcessing = false
    @Published var discoveredReaders: [Reader] = []

    var currentState: State = .initial
    private var connectedReader: Reader?
    private var discoveryTask: Task<Void, Never>?

    enum State {
        case initial
        case discovering
        case connecting
        case connected
        case processing
    }

    func discoverReaders() async {
        isProcessing = true
        statusMessage = "Discovering readers..."
        currentState = .discovering
        discoveredReaders = []

        do {
            let config = try TapToPayDiscoveryConfigurationBuilder().setSimulated(false).build()

            let discoverReadersStream = Terminal.shared.discoverReaders(config)

            for try await readers in discoverReadersStream {
                statusMessage = "\(readers.count) readers found"
                discoveredReaders = readers
            }

            isProcessing = false

        } catch {
            statusMessage = "Discovery failed: \(error.localizedDescription)"
            isProcessing = false
            currentState = .initial
        }
    }

    func selectReader(_ reader: Reader) async {
        currentState = .connecting
        await connectToReader(reader)
    }

    func connectToReader(_ reader: Reader) async {
        statusMessage = "Connecting to reader..."

        do {
            let locationId: String
            if let existingLocationId = reader.locationId {
                locationId = existingLocationId
            } else {
                statusMessage = "Creating location..."
                locationId = try await APIClient.shared.createLocation()
            }

            let connectionConfig = try TapToPayConnectionConfigurationBuilder(
                delegate: self,
                locationId: locationId
            ).build()

            connectedReader = try await Terminal.shared.connectReader(reader, connectionConfig: connectionConfig)

            statusMessage = "Connected to reader"
            buttonTitle = "Make a Payment"
            currentState = .connected
            isProcessing = false
            discoveredReaders = []

        } catch {
            statusMessage = "Connection failed: \(error.localizedDescription)"
            isProcessing = false
            currentState = .initial
        }
    }

    func restart() async {
        isProcessing = true
        statusMessage = "Disconnecting..."

        do {
            try await Terminal.shared.disconnectReader()
        } catch {
            // Ignore disconnect errors
        }

        connectedReader = nil
        discoveredReaders = []
        statusMessage = "Ready to connect"
        buttonTitle = "Discover Readers"
        currentState = .initial
        isProcessing = false
    }

    func collectPayment() async {
        isProcessing = true
        statusMessage = "Creating payment..."
        currentState = .processing

        do {
            let params = try PaymentIntentParametersBuilder(amount: 1000,
                                                            currency: "usd")
                .setPaymentMethodTypes([.cardPresent])
                .build()

            let paymentIntent = try await Terminal.shared.createPaymentIntent(params)
            statusMessage = "Processing payment..."

            let processedIntent = try await Terminal.shared.processPaymentIntent(paymentIntent, collectConfig: nil, confirmConfig: nil)

            if let stripeId = processedIntent.stripeId {
                try await APIClient.shared.capturePaymentIntent(stripeId)
                statusMessage = "Payment captured successfully!"
            } else {
                statusMessage = "Payment collected offline"
            }

            buttonTitle = "Make Another Payment"
            currentState = .connected
            isProcessing = false

        } catch {
            statusMessage = "Payment failed: \(error.localizedDescription)"
            isProcessing = false
            currentState = .connected
        }
    }
}


// MARK: - Tap To Pay Reader Delegate
extension TerminalManager: @MainActor TapToPayReaderDelegate {
    func tapToPayReader(_ reader: Reader, didStartInstallingUpdate update: ReaderSoftwareUpdate, cancelable: Cancelable?) {
        statusMessage = "Installing update..."
    }

    func tapToPayReader(_ reader: Reader, didReportReaderSoftwareUpdateProgress progress: Float) {
        statusMessage = "Update progress: \(Int(progress * 100))%"
    }

    func tapToPayReader(_ reader: Reader, didFinishInstallingUpdate update: ReaderSoftwareUpdate?, error: Error?) {
        if let error = error {
            statusMessage = "Update failed: \(error.localizedDescription)"
        } else {
            statusMessage = "Update complete"
        }
    }

    func tapToPayReader(_ reader: Reader, didRequestReaderDisplayMessage displayMessage: ReaderDisplayMessage) {
        statusMessage = Terminal.stringFromReaderDisplayMessage(displayMessage)
    }

    func tapToPayReader(_ reader: Reader, didRequestReaderInput inputOptions: ReaderInputOptions = []) {
        statusMessage = Terminal.stringFromReaderInputOptions(inputOptions)
    }
}
