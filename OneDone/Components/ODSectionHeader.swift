import SwiftUI

struct ODSectionHeader: View {
    let title: String
    let subtitle: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(OneDoneStyle.sectionTitleFont)
                .foregroundStyle(ODColor.textPrimary)

            if let subtitle {
                Text(subtitle)
                    .font(OneDoneStyle.subheadlineFont)
                    .foregroundStyle(ODColor.textSecondary)
            }
        }
    }
}
