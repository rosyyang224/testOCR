//import FoundationModels
//
//struct SummarizeActivityTool: Tool {
//    let name = "summarizeActivity"
//    let description = """
//    General-purpose tool that decides which summarization to run based on user's most recent activity and interest.
//    This is useful when no clear topic is stated, and recent user logs should determine the focus.
//    """
//
//    @Generable
//    struct Arguments {
//        @Guide(description: "User's recent activity log or inferred focus (e.g. ['transactions', 'portfolio_value'])")
//        var topics: [String]
//    }
//
//    func call(arguments: Arguments) async throws -> ToolOutput {
//        let prioritized = arguments.topics.joined(separator: ", ")
//        let summary = "Based on your recent activity, we will prioritize summaries for: \(prioritized)"
//        return .init(summary)
//    }
//}
