import SwiftUI

struct Card<Content: View>: View {
    var padding: CGFloat = 14
    @ViewBuilder var content: Content
    var body: some View {
        VStack(alignment: .leading, spacing: 0) { content }
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Theme.card, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }
}

struct SectionTitle: View {
    let key: String
    var body: some View {
        Text(Loc.s(key))
            .font(.caption.weight(.bold)).tracking(0.8)
            .foregroundStyle(Theme.muted)
            .padding(.horizontal, 6)
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityAddTraits(.isHeader)
    }
}

struct ScreenTitle: View {
    let title: String
    var subtitle: String?
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title).font(.system(size: 30, weight: .bold)).foregroundStyle(Theme.text)
            if let subtitle { Text(subtitle).font(.footnote).foregroundStyle(Theme.muted) }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct ToggleRow: View {
    let title: String
    var subtitle: String?
    @Binding var isOn: Bool
    var body: some View {
        Toggle(isOn: $isOn) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.body.weight(.semibold)).foregroundStyle(Theme.text)
                if let subtitle { Text(subtitle).font(.caption).foregroundStyle(Theme.muted) }
            }
        }
        .tint(Theme.accent)
        .padding(.vertical, 10)
    }
}

struct RowDivider: View {
    var body: some View { Rectangle().fill(Theme.line).frame(height: 1) }
}

struct ChipPicker<T: Hashable>: View {
    let options: [(T, String)]
    @Binding var selection: T
    var body: some View {
        FlowLayout(spacing: 6) {
            ForEach(options, id: \.0) { option in
                let selected = option.0 == selection
                Button { selection = option.0 } label: {
                    Text(option.1).font(.footnote.weight(.semibold))
                        .padding(.horizontal, 12).frame(minHeight: 34)
                        .background(selected ? Theme.accent : Color.clear, in: Capsule())
                        .overlay(Capsule().stroke(selected ? Theme.accent : Theme.line, lineWidth: 1))
                        .foregroundStyle(selected ? Theme.onAccent : Theme.text)
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(selected ? .isSelected : [])
            }
        }
    }
}

/// Simple wrapping layout for chips.
struct FlowLayout: Layout {
    var spacing: CGFloat = 6

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width ?? .infinity
        var x: CGFloat = 0, y: CGFloat = 0, rowHeight: CGFloat = 0, maxX: CGFloat = 0
        for v in subviews {
            let s = v.sizeThatFits(.unspecified)
            if x > 0 && x + s.width > width { x = 0; y += rowHeight + spacing; rowHeight = 0 }
            x += s.width + spacing
            maxX = max(maxX, x - spacing)
            rowHeight = max(rowHeight, s.height)
        }
        return CGSize(width: min(maxX, width), height: y + rowHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX, y = bounds.minY, rowHeight: CGFloat = 0
        for v in subviews {
            let s = v.sizeThatFits(.unspecified)
            if x > bounds.minX && x + s.width > bounds.maxX { x = bounds.minX; y += rowHeight + spacing; rowHeight = 0 }
            v.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(s))
            x += s.width + spacing
            rowHeight = max(rowHeight, s.height)
        }
    }
}

struct ScreenScroll<Content: View>: View {
    @ViewBuilder var content: Content
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) { content }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
        }
        .background(Theme.background.ignoresSafeArea())
    }
}

struct CheckCircle: View {
    let checked: Bool
    var size: CGFloat = 30
    var body: some View {
        ZStack {
            Circle().fill(checked ? Theme.accent : Color.clear)
            Circle().stroke(checked ? Theme.accent : Theme.muted.opacity(0.5), lineWidth: 2)
            if checked {
                Image(systemName: "checkmark").font(.system(size: size * 0.45, weight: .heavy)).foregroundStyle(Theme.onAccent)
            }
        }
        .frame(width: size, height: size)
    }
}
