import SwiftUI

/// Renders a `LegalContent.Doc` (Privacy Policy or Terms of Service) in the stark
/// theme — the same text as the website, available offline and at App Review.
/// Presented as a sheet from Settings → About & legal.
struct LegalScreen: View {
    let doc: LegalContent.Doc
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                SignalBackground()

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: RinklerSpacing.lg) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(doc.title)
                                .font(RinklerFonts.sans(28, .bold))
                                .foregroundStyle(RinklerColors.signalText)
                            Text("Effective \(LegalContent.effective)")
                                .font(RinklerFonts.mono(12, .regular))
                                .foregroundStyle(RinklerColors.signalTextFaint)
                        }

                        Text(doc.lead)
                            .font(RinklerFonts.sans(15, .regular))
                            .foregroundStyle(RinklerColors.signalTextDim)
                            .fixedSize(horizontal: false, vertical: true)
                            .lineSpacing(3)

                        ForEach(Array(doc.sections.enumerated()), id: \.offset) { _, section in
                            sectionView(section.title, section.body)
                        }

                        Text("Questions? \(LegalContent.contactEmail)")
                            .font(RinklerFonts.sans(13, .regular))
                            .foregroundStyle(RinklerColors.signalTextFaint)
                            .padding(.top, RinklerSpacing.sm)
                    }
                    .padding(RinklerSpacing.lg)
                    .padding(.bottom, 60)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .navigationTitle(doc.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(RinklerColors.signalBlue)
                }
            }
        }
    }

    @ViewBuilder
    private func sectionView(_ title: String, _ blocks: [LegalContent.Block]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(RinklerFonts.sans(18, .semibold))
                .foregroundStyle(RinklerColors.signalText)

            ForEach(Array(blocks.enumerated()), id: \.offset) { _, block in
                switch block {
                case .text(let body):
                    Text(body)
                        .font(RinklerFonts.sans(14, .regular))
                        .foregroundStyle(RinklerColors.signalTextDim)
                        .fixedSize(horizontal: false, vertical: true)
                        .lineSpacing(3)
                case .bullets(let items):
                    VStack(alignment: .leading, spacing: 7) {
                        ForEach(items, id: \.self) { item in
                            HStack(alignment: .top, spacing: 9) {
                                Circle()
                                    .fill(RinklerColors.signalBlue)
                                    .frame(width: 5, height: 5)
                                    .padding(.top, 7)
                                Text(item)
                                    .font(RinklerFonts.sans(14, .regular))
                                    .foregroundStyle(RinklerColors.signalTextDim)
                                    .fixedSize(horizontal: false, vertical: true)
                                    .lineSpacing(3)
                            }
                        }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#Preview {
    LegalScreen(doc: LegalContent.privacy)
}
