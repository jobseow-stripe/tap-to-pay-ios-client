// APIClient.swift

import Foundation
import StripeTerminal

class APIClient: ConnectionTokenProvider {

    static let shared = APIClient()

    static let backendUrl = URL(string: "https://<BACKEND_URL>")!

    func fetchConnectionToken(_ completion: @escaping ConnectionTokenCompletionBlock) {
        Task {
            do {
                let secret = try await fetchConnectionTokenAsync()
                completion(secret, nil)
            } catch {
                completion(nil, error)
            }
        }
    }
    
    func createLocation() async throws -> String {
        let url = URL(string: "/create_location", relativeTo: APIClient.backendUrl)!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let (data, _) = try await URLSession.shared.data(for: request)
        let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]
        guard let id = json["location"] as? String else {
            throw NSError(domain: "APIClient", code: 0, userInfo: [NSLocalizedDescriptionKey: "Missing location id"])
        }
        return id
    }

   private func fetchConnectionTokenAsync() async throws -> String {
        let url = URL(string: "/connection_token", relativeTo: APIClient.backendUrl)!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw NSError(domain: "com.stripe-terminal-ios.example",
                     code: 1000,
     userInfo: [NSLocalizedDescriptionKey: "Invalid response from ConnectionToken endpoint"])
        }
        
        let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
        guard let secret = json?["secret"] as? String else {
            throw NSError(domain: "com.stripe-terminal-ios.example",
         code: 2000,
      userInfo: [NSLocalizedDescriptionKey: "Missing 'secret' in ConnectionToken JSON response"])
        }
        
        return secret
    }

   func capturePaymentIntent(_ paymentIntentId: String) async throws {
        let url = URL(string: "/capture_payment_intent", relativeTo: APIClient.backendUrl)!
        
        let parameters = ["payment_intent_id": paymentIntentId]
        let jsonData = try JSONSerialization.data(withJSONObject: parameters)
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
        request.httpBody = jsonData
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NSError(domain: "com.stripe-terminal-ios.example",
                         code: 0,
                         userInfo: [NSLocalizedDescriptionKey: "Invalid response"])
        }
        
        switch httpResponse.statusCode {
        case 200..<300:
            return
        case 402:
            let description = String(data: data, encoding: .utf8) ?? "Failed to capture payment intent"
            throw NSError(domain: "com.stripe-terminal-ios.example",
                         code: 2,
   userInfo: [NSLocalizedDescriptionKey: description])
        default:
            throw NSError(domain: "com.stripe-terminal-ios.example",
                         code: 0,
  userInfo: [NSLocalizedDescriptionKey: "Capture failed with status code \(httpResponse.statusCode)"])
        }
    }
}
