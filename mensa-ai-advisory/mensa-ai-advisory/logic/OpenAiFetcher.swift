import Foundation
import HTTPTypes
import HTTPTypesFoundation

enum PollingError: Error {
    case pollingFailed(reason: String)
}

extension HTTPField.Name {
    static let openaibeta = Self("OpenAI-Beta")!
}

class OpenAiFetcher: ObservableObject {
    @Published var responseStrings: MealResponse = MealResponse(meals: [], comment: "", funny_title: "Nothing to see here")
    
    var openAiKey: String
    
    let base = "api.openai.com/v1/threads/"
    let createAndRunThreadEndpoint = "runs"
    let retrieveThreadRunEndpoint = "{thread_id}/runs/{run_id}"
    let retrieveMessagesEndpoint = "{thread_id}/messages"

    let openAImodel = "gpt-4o-mini"
    let openAIAssistant = "asst_PBj8qdbCoPXkwyBiSHCp45BO"
    
    init(openAiKey: String) {
        self.openAiKey = openAiKey
    }

    convenience init() {
        var key: String = ""
        if let path = Bundle.main.path(forResource: "Keys", ofType: "plist"),
           let dict = NSDictionary(contentsOfFile: path) as? [String: Any],
           let retrievedKey = dict["OPEN_AI_API_KEY"] as? String {
            key = retrievedKey
        }
        self.init(openAiKey: key)
    }
    
    func jsonPrint(data: Data) -> String {
        let jsonString = String(data: data, encoding: .utf8)
        return jsonString ?? "No JSON"
    }
    
    func createAndRunThread(content: String) async throws -> ([String: Any], Data) {
        var req = HTTPRequest(method: .post, scheme: "https", authority: base, path: createAndRunThreadEndpoint)
        req.headerFields[.authorization] = "Bearer " + openAiKey
        req.headerFields[.openaibeta] = "assistants=v2"
        req.headerFields[.contentType] = "application/json"
        
        let body: [String: Any] = [
            "assistant_id": openAIAssistant,
            "thread": [
                "messages": [
                    [
                        "role": "user",
                        "content": content
                     ]
                ]
            ]
        ]
        let json = try JSONSerialization.data(withJSONObject: body, options: .prettyPrinted)
        let (responseBody, response) = try await URLSession.shared.upload(for: req, from: json)
        guard (200...299).contains(response.status.code) else {
            throw URLError(.badServerResponse)
        }
        return (try JSONSerialization.jsonObject(with: responseBody, options: []) as! [String: Any], responseBody)
    }
    
    func retrieveThreadRun(threadId: String, runId: String) async throws -> ([String: Any], Data)  {
        let preparedUrl: String = retrieveThreadRunEndpoint
            .replacingOccurrences(of: "{thread_id}", with: threadId)
            .replacingOccurrences(of: "{run_id}", with: runId)
        
        var req = HTTPRequest(method: .get, scheme: "https", authority: base, path: preparedUrl)
        req.headerFields[.authorization] = "Bearer " + openAiKey
        req.headerFields[.openaibeta] = "assistants=v2"
        
        let (responseBody, response) = try await URLSession.shared.data(for: req)
        guard (200...299).contains(response.status.code) else {
            throw URLError(.badServerResponse)
        }
        return (try JSONSerialization.jsonObject(with: responseBody, options: []) as! [String: Any], responseBody)
    }
    
    func retrieveMessages(threadId: String) async throws -> ([String: Any], Data) {
        let preparedUrl: String = retrieveMessagesEndpoint
            .replacingOccurrences(of: "{thread_id}", with: threadId)
        
        var req = HTTPRequest(method: .get, scheme: "https", authority: base, path: preparedUrl)
        req.headerFields[.authorization] = "Bearer " + openAiKey
        req.headerFields[.openaibeta] = "assistants=v2"
        req.headerFields[.contentType] = "application/json"
        
        let (responseBody, response) = try await URLSession.shared.data(for: req)
        guard (200...299).contains(response.status.code) else {
            throw URLError(.badServerResponse)
        }
        return (try JSONSerialization.jsonObject(with: responseBody, options: []) as! [String: Any], responseBody)
    }
    
    func parseMessages(messages: [String: Any]) throws -> MealResponse {
        let defaultMealResponse = MealResponse(meals: [], comment: "", funny_title: "Nothing to see here")
        guard messages.keys.contains("object") && messages.keys.contains("data"),
              let isList = messages["object"] as? String, isList.lowercased() == "list",
              let data = messages["data"] as? [[String: Any]]
        else {
            return defaultMealResponse
        }
        
        var assistantMessages = data.filter { element in
            if let role = element["role"] as? String {
                return role == "assistant"
            } else {
                return false
            }
        }
        guard assistantMessages.count > 0 else {
            return defaultMealResponse
        }
        
        let message = assistantMessages.removeFirst()
        print("")
        guard message.keys.contains("content"),
              let contentArray = message["content"] as? [[String: Any]],
              let inner = contentArray.first,
              let value = inner["text"] as? [String: Any],
              let text = value["value"] as? String
        else {
            return defaultMealResponse
        }
        
        let mealResonse = try JSONDecoder().decode(MealResponse.self, from: text.data(using: .utf8)!)
        return mealResonse
    }
    
    func pollUntilStatusCompleted(threadId: String, runId: String, interval: TimeInterval) async throws {
        var completed = false
        repeat {
            do {
                let (responseJson, _): ([String: Any], Data) = try await retrieveThreadRun(threadId: threadId, runId: runId)
                if let status = responseJson["status"] as? String, status.lowercased() == "completed" {
                    completed = true
                } else {
                    print("Task not completed, polling again in \(interval) seconds...")
                    try await Task.sleep(nanoseconds: UInt64(interval * 1_000_000_000))
                }
            } catch {
                throw PollingError.pollingFailed(reason: "An error occurred: \(error.localizedDescription)")
            }
        } while !completed
    }
}
