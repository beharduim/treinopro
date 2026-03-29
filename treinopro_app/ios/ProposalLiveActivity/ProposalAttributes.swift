import ActivityKit
import Foundation

struct ProposalAttributes: ActivityAttributes {
    // Static data — set when Live Activity starts
    let proposalId: String

    // Dynamic data — updated via push or local updates
    struct ContentState: Codable, Hashable {
        let studentName: String
        let location: String
        let modality: String
        let price: String
        let trainingTime: String
        let expiresAt: Date
        let proposalStatus: String // "pending", "accepted", "rejected", "expired"
    }
}
