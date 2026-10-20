import Foundation

/// What OMP does while it writes an answer, apart from the text: thinking, retries, compaction and host tool calls.
public enum OMPActivity: Sendable, Equatable {
    /// A piece of the model's reasoning, as it streams.
    case thinking(String)
    /// OMP is retrying the provider request; `attempt` is the attempt that starts, out of `maxAttempts`.
    case retryStarted(attempt: Int, maxAttempts: Int)
    case retryEnded
    /// OMP is summarizing the conversation to fit the context.
    case compactionStarted
    case compactionEnded
    /// OMP called a host tool; the call ends with `toolFinished` carrying the same `id`.
    case toolStarted(id: String, name: String, arguments: JSONValue)
    case toolFinished(id: String)
}
