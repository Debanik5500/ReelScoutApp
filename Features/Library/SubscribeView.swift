import SwiftUI

/// "Your plan": how many reels are left this month, and the plans. No payments yet, so paid plans read
/// "Coming soon" with a notify-me toggle. Plans and limits come from the server config.
struct SubscribeView: View {
    @EnvironmentObject var store: ReelStore
    @Environment(\.dismiss) private var dismiss
    @AppStorage("notifyPlanIDs") private var notifyRaw = ""

    private var notifyIDs: Set<String> { Set(notifyRaw.split(separator: ",").map(String.init)) }
    private var currentPlanID: String { store.quota?.plan ?? "free" }
    /// The free allowance, straight from the plans config so the text can never disagree with the limit.
    private var freeReels: Int { store.plans.first(where: \.isFree)?.monthlyReels ?? 5 }

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter
    }()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                header
                usageCard
                Text("Plans").font(Theme.Font.display(26)).padding(.top, 4)
                ForEach(store.plans) { plan in planCard(plan) }
                Text("A reel is counted when Kept starts reading it, and given back if it fails. Reels you already saved never count again.")
                    .font(Theme.Font.body(12)).foregroundStyle(Theme.textSecondary)
            }
            .padding(.horizontal, 20).padding(.top, 8).padding(.bottom, 40)
        }
        .background(Theme.background)
        .task { await store.refreshQuota() }
    }

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Your plan").font(Theme.Font.display(38))
                Text("Every account gets \(freeReels) reels a month free.")
                    .font(Theme.Font.body(14)).foregroundStyle(Theme.textSecondary)
            }
            Spacer()
            Button { dismiss() } label: {
                Image(systemName: "xmark").font(.system(size: 14, weight: .semibold))
                    .frame(width: 36, height: 36).background(Theme.surface2, in: Circle())
            }
            .foregroundStyle(Theme.text)
        }
        .padding(.top, 16)
    }

    // MARK: - Usage

    private var usageCard: some View {
        let quota = store.quota
        let limit = quota?.limit
        let used = quota?.used ?? 0
        let remaining = quota?.remaining
        return VStack(alignment: .leading, spacing: 12) {
            if let limit {
                HStack(alignment: .firstTextBaseline) {
                    Text("\(remaining ?? limit)").font(Theme.Font.display(52))
                    Text("of \(limit) reels left this month").font(Theme.Font.body(15)).foregroundStyle(Theme.textSecondary)
                }
                ProgressView(value: Double(min(used, limit)), total: Double(max(limit, 1)))
                    .tint(quota?.isOut == true ? Theme.accentHighlight : Theme.success)
                if let resets = quota?.resetsAt {
                    Text("Resets \(Self.dateFormatter.string(from: resets))")
                        .font(Theme.Font.body(12)).foregroundStyle(Theme.textSecondary)
                }
                if quota?.isOut == true {
                    Label("You've used this month's reels. New reels start again when it resets.",
                          systemImage: "exclamationmark.circle.fill")
                        .font(Theme.Font.body(13, weight: .semibold)).foregroundStyle(Theme.accentHighlight)
                }
            } else {
                Text(quota == nil ? "Checking your reels…" : "No monthly limit on this device.")
                    .font(Theme.Font.body(15)).foregroundStyle(Theme.textSecondary)
            }
        }
        .padding(18).frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.aiBg, in: RoundedRectangle(cornerRadius: 26, style: .continuous))
    }

    // MARK: - Plans

    private func planCard(_ plan: Plan) -> some View {
        let isCurrent = plan.id == currentPlanID
        return VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                Text(plan.name).font(Theme.Font.display(28))
                if isCurrent {
                    Text("Your plan").font(Theme.Font.body(11, weight: .bold))
                        .padding(.horizontal, 9).padding(.vertical, 4)
                        .background(Theme.placeBg, in: Capsule()).foregroundStyle(Theme.placeFg)
                }
                Spacer()
                Text(priceText(plan)).font(Theme.Font.body(16, weight: .semibold))
            }
            Text(plan.tagline).font(Theme.Font.body(13)).foregroundStyle(Theme.textSecondary)
            VStack(alignment: .leading, spacing: 6) {
                ForEach(plan.features, id: \.self) { feature in
                    Label(feature, systemImage: "checkmark").font(Theme.Font.body(13))
                        .labelStyle(CheckLabelStyle())
                }
            }
            if !isCurrent { action(for: plan) }
        }
        .padding(18).frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.surface, in: RoundedRectangle(cornerRadius: 26, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 26, style: .continuous)
            .stroke(isCurrent ? Theme.success : .clear, lineWidth: 2))
    }

    private func priceText(_ plan: Plan) -> String {
        plan.isFree ? "Free" : String(format: "$%.2f / month", plan.priceUSDMonth)
    }

    @ViewBuilder
    private func action(for plan: Plan) -> some View {
        if plan.available {
            // Payments are not wired up yet, so an available paid plan is only a placeholder.
            Text("Available soon").font(Theme.Font.body(13)).foregroundStyle(Theme.textSecondary)
        } else {
            let subscribed = notifyIDs.contains(plan.id)
            Button { toggleNotify(plan.id) } label: {
                Label(subscribed ? "We'll tell you when it's ready" : "Coming soon · Notify me",
                      systemImage: subscribed ? "bell.fill" : "bell")
                    .font(Theme.Font.body(14, weight: .semibold))
                    .frame(maxWidth: .infinity).frame(height: 46)
                    .background(subscribed ? Theme.placeBg : Theme.surface2, in: Capsule())
                    .foregroundStyle(subscribed ? Theme.placeFg : Theme.text)
            }
        }
    }

    private func toggleNotify(_ id: String) {
        var ids = notifyIDs
        if ids.contains(id) { ids.remove(id) } else { ids.insert(id) }
        notifyRaw = ids.sorted().joined(separator: ",")
    }
}

private struct CheckLabelStyle: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: 8) {
            configuration.icon.font(.system(size: 11, weight: .bold)).foregroundStyle(Theme.success)
            configuration.title
        }
    }
}
