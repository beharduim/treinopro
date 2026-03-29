import WidgetKit
import SwiftUI
import ActivityKit

@available(iOS 16.1, *)
struct ProposalLiveActivityWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: ProposalAttributes.self) { context in
            // Lock Screen / Banner UI
            lockScreenView(context: context)
        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded Dynamic Island
                DynamicIslandExpandedRegion(.leading) {
                    Image(systemName: "figure.run")
                        .font(.title2)
                        .foregroundColor(.orange)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text(context.state.price)
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.green)
                }
                DynamicIslandExpandedRegion(.center) {
                    VStack(spacing: 4) {
                        Text(context.state.studentName)
                            .font(.headline)
                            .lineLimit(1)
                        Text(context.state.location)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                }
                DynamicIslandExpandedRegion(.bottom) {
                    HStack(spacing: 12) {
                        // Accept button
                        Link(destination: URL(string: "treinopro://proposal-action/\(context.attributes.proposalId)/accept")!) {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                Text("Aceitar")
                            }
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color.green)
                            .cornerRadius(20)
                        }

                        // Reject button
                        Link(destination: URL(string: "treinopro://proposal-action/\(context.attributes.proposalId)/reject")!) {
                            HStack {
                                Image(systemName: "xmark.circle.fill")
                                Text("Rejeitar")
                            }
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color.red.opacity(0.8))
                            .cornerRadius(20)
                        }
                    }
                }
            } compactLeading: {
                // Compact leading — emoji + timer
                Image(systemName: "figure.run")
                    .foregroundColor(.orange)
            } compactTrailing: {
                // Compact trailing — countdown
                Text(context.state.expiresAt, style: .timer)
                    .monospacedDigit()
                    .font(.caption2)
                    .frame(width: 40)
            } minimal: {
                // Minimal — just the icon
                Image(systemName: "figure.run")
                    .foregroundColor(.orange)
            }
            .widgetURL(URL(string: "treinopro://proposal/\(context.attributes.proposalId)"))
        }
    }

    @ViewBuilder
    private func lockScreenView(context: ActivityViewContext<ProposalAttributes>) -> some View {
        let isResolved = context.state.proposalStatus == "accepted" ||
                         context.state.proposalStatus == "rejected" ||
                         context.state.proposalStatus == "expired"

        VStack(spacing: 12) {
            // Header
            HStack {
                Image(systemName: "figure.run")
                    .font(.title2)
                    .foregroundColor(.orange)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Nova Proposta de Treino")
                        .font(.headline)
                        .foregroundColor(.white)
                    if !isResolved {
                        Text(context.state.expiresAt, style: .timer)
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                }
                Spacer()
                Text(context.state.price)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.green)
            }

            // Details
            HStack(spacing: 16) {
                Label(context.state.studentName, systemImage: "person.fill")
                    .font(.subheadline)
                    .lineLimit(1)
                Spacer()
                Label(context.state.modality, systemImage: "dumbbell.fill")
                    .font(.caption)
                    .lineLimit(1)
            }
            .foregroundColor(.white.opacity(0.9))

            HStack(spacing: 16) {
                Label(context.state.location, systemImage: "mappin.and.ellipse")
                    .font(.caption)
                    .lineLimit(1)
                Spacer()
                Label(context.state.trainingTime, systemImage: "clock.fill")
                    .font(.caption)
            }
            .foregroundColor(.white.opacity(0.7))

            // Action buttons (only show for pending)
            if !isResolved {
                HStack(spacing: 12) {
                    Link(destination: URL(string: "treinopro://proposal-action/\(context.attributes.proposalId)/accept")!) {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                            Text("Aceitar")
                        }
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(Color.green)
                        .cornerRadius(12)
                    }

                    Link(destination: URL(string: "treinopro://proposal-action/\(context.attributes.proposalId)/reject")!) {
                        HStack {
                            Image(systemName: "xmark.circle.fill")
                            Text("Rejeitar")
                        }
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(Color.red.opacity(0.8))
                        .cornerRadius(12)
                    }
                }
            } else {
                // Status indicator
                HStack {
                    Image(systemName: statusIcon(for: context.state.proposalStatus))
                    Text(statusText(for: context.state.proposalStatus))
                }
                .font(.subheadline.weight(.semibold))
                .foregroundColor(statusColor(for: context.state.proposalStatus))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(statusColor(for: context.state.proposalStatus).opacity(0.2))
                .cornerRadius(12)
            }
        }
        .padding(16)
        .background(
            LinearGradient(
                colors: [Color(red: 0.12, green: 0.12, blue: 0.15), Color(red: 0.08, green: 0.08, blue: 0.1)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .widgetURL(URL(string: "treinopro://proposal/\(context.attributes.proposalId)"))
    }

    private func statusIcon(for status: String) -> String {
        switch status {
        case "accepted": return "checkmark.circle.fill"
        case "rejected": return "xmark.circle.fill"
        case "expired": return "clock.badge.exclamationmark"
        default: return "questionmark.circle"
        }
    }

    private func statusText(for status: String) -> String {
        switch status {
        case "accepted": return "Proposta Aceita!"
        case "rejected": return "Proposta Rejeitada"
        case "expired": return "Proposta Expirada"
        default: return status
        }
    }

    private func statusColor(for status: String) -> Color {
        switch status {
        case "accepted": return .green
        case "rejected": return .red
        case "expired": return .orange
        default: return .gray
        }
    }
}
