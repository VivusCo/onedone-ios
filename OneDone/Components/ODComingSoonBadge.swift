import SwiftUI

struct ODComingSoonBadge: View {
    var text: String = "Coming soon"

    var body: some View {
        ODStatusBadge(title: text, tone: .locked)
    }
}

#Preview {
    ODComingSoonBadge(text: "Attachments coming soon")
        .padding()
        .oneDoneScreen()
}
