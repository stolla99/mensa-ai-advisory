//
//  ContentView 2.swift
//  MensaAdvisory
//
//  Created by Arne Stoll on 2/3/25.
//


import LocalAuthentication
import Security
import SwiftUI

// MARK: - Authenticate User with Biometrics
func authenticateUser(completion: @escaping (Bool) -> Void) {
    let context = LAContext()
    var error: NSError?

    if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
        context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: "Authenticate to access sensitive data") { success, error in
            DispatchQueue.main.async {
                completion(success)
            }
        }
    } else {
        completion(false)
    }
}

// MARK: - Store Key in Keychain
func storeKeyInKeychain(key: String, value: String) -> Bool {
    let keyData = Data(value.utf8)

    let query: [String: Any] = [
        kSecClass as String: kSecClassGenericPassword,
        kSecAttrAccount as String: key,
        kSecValueData as String: keyData,
        kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
    ]

    // Delete existing key if present
    SecItemDelete(query as CFDictionary)

    // Add new key
    let status = SecItemAdd(query as CFDictionary, nil)
    return status == errSecSuccess
}

// MARK: - Retrieve Key from Keychain
func retrieveKeyFromKeychain(key: String) -> String? {
    let query: [String: Any] = [
        kSecClass as String: kSecClassGenericPassword,
        kSecAttrAccount as String: key,
        kSecReturnData as String: true,
        kSecMatchLimit as String: kSecMatchLimitOne
    ]

    var result: AnyObject?
    let status = SecItemCopyMatching(query as CFDictionary, &result)

    guard status == errSecSuccess, let data = result as? Data else {
        return nil
    }

    return String(data: data, encoding: .utf8)
}

// MARK: - Delete Key from Keychain
func deleteKeyFromKeychain(key: String) {
    let query: [String: Any] = [
        kSecClass as String: kSecClassGenericPassword,
        kSecAttrAccount as String: key
    ]

    SecItemDelete(query as CFDictionary)
}

// MARK: - Example Usage in SwiftUI
struct FFContentView: View {
    @State private var isAuthenticated = false
    @State private var storedKey: String?

    var body: some View {
        VStack(spacing: 20) {
            Button("Authenticate") {
                authenticateUser { success in
                    if success {
                        isAuthenticated = true
                    }
                }
            }
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(10)

            if isAuthenticated {
                Button("Store Key") {
                    let success = storeKeyInKeychain(key: "secureKey", value: "my_secret_value")
                    print(success ? "Key Stored!" : "Failed to Store Key")
                }
                .padding()
                .background(Color.green)
                .foregroundColor(.white)
                .cornerRadius(10)

                Button("Retrieve Key") {
                    storedKey = retrieveKeyFromKeychain(key: "secureKey")
                }
                .padding()
                .background(Color.orange)
                .foregroundColor(.white)
                .cornerRadius(10)

                Button("Delete Key") {
                    deleteKeyFromKeychain(key: "secureKey")
                    storedKey = nil
                }
                .padding()
                .background(Color.red)
                .foregroundColor(.white)
                .cornerRadius(10)

                if let storedKey = storedKey {
                    Text("Stored Key: \(storedKey)")
                        .foregroundColor(.black)
                        .padding()
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(8)
                }
            }
        }
        .padding()
    }
}

// MARK: - Preview
struct FFContentView_Previews: PreviewProvider {
    static var previews: some View {
        FFContentView()
    }
}
