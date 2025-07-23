import SwiftUI

struct ChatMessage: Identifiable {
    let id = UUID()
    let isUser: Bool
    let text: String
}

struct QueryView: View {
    @State private var userQuery: String = ""
    @State private var messages: [ChatMessage] = []
    @State private var model = QueryLanguageSession()


    var body: some View {
        VStack {
            Text("Financial Assistant")
                .font(.title)
                .padding(.top)

            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(messages) { message in
                        HStack {
                            if message.isUser {
                                Spacer()
                                Text(message.text)
                                    .padding()
                                    .background(Color.blue.opacity(0.2))
                                    .cornerRadius(10)
                                    .frame(maxWidth: 250, alignment: .trailing)
                            } else {
                                Text(message.text)
                                    .padding()
                                    .background(Color.gray.opacity(0.1))
                                    .cornerRadius(10)
                                    .frame(maxWidth: 250, alignment: .leading)
                                Spacer()
                            }
                        }
                    }
                }
                .padding()
            }

            // Input section
            HStack {
                TextField("Type your question...", text: $userQuery)
                    .textFieldStyle(RoundedBorderTextFieldStyle())

                Button("Send") {
                    print("whats good")
                    let query = userQuery.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !query.isEmpty else { return }

                    messages.append(ChatMessage(isUser: true, text: query))
                    userQuery = ""

                    Task {
                        do {
                            let reply = try await model.send(query)
                            messages.append(ChatMessage(isUser: false, text: reply))
                        } catch {
                            messages.append(ChatMessage(isUser: false, text: "Error: \(error.localizedDescription)"))
                        }
                    }
                }
            }
            .padding()
            
            // Test button
            Button("Run Quick Tests") {
                Task {
////                    let quickTest = QuickValidationTest()
////                    await quickTest.runQuickValidation()
////                    let focusedTest = FocusedHoldingsTest()
////                    await focusedTest.runFocusedTests()
//                    
//                    let test = FocusedHoldingsTest()
//                    await test.runFocusedTests()
//                    await test.debugAvailableData()
                }
            }
            .padding(.bottom)
        }
    }
}
