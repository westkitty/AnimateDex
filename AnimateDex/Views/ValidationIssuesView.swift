import SwiftUI

struct ValidationIssuesView: View {
    let issues: [ValidationIssue]

    var body: some View {
        GroupBox("Validation") {
            if issues.isEmpty {
                Text("No validation issues.")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                List(issues) { issue in
                    VStack(alignment: .leading, spacing: 3) {
                        Text(issue.message)
                        Text("\(issue.severity.rawValue.uppercased()) • \(issue.code)")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(minHeight: 150)
            }
        }
    }
}
