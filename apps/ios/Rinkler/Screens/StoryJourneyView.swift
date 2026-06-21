import SwiftUI

/// Story Mode — Journey.
///
/// The ongoing half of Story Mode. It turns the user's real focus history into a
/// "restore the sky" progression: cumulative protected time, sessions, and
/// streak unlock chapters from First Light to Clear Sky. The sky at the top is
/// rendered at the user's *earned* clarity, so this screen is a living portrait
/// of how far they've pulled the world back toward dawn.
struct StoryJourneyView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var sessions: FocusSessionStore

    private var progress: StoryProgress { sessions.storyProgress }
    private var current: StoryChapter? { Story.currentChapter(progress) }
    private var next: StoryChapter? { Story.nextChapter(progress) }

    var body: some View {
        ZStack {
            SkyBackgroundView(clarity: Story.earnedClarity(progress))

            ScrollView {
                VStack(alignment: .leading, spacing: RinklerSpacing.lg) {
                    headerCard
                    nextCard
                    chaptersList
                }
                .padding(.horizontal, RinklerSpacing.lg)
                .padding(.top, RinklerSpacing.sm)
                .padding(.bottom, RinklerSpacing.xxl)
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button { dismiss() } label: { BackArrowView() }
            }
            ToolbarItem(placement: .principal) {
                Text("YOUR JOURNEY")
                    .font(RinklerFonts.headerTitle)
                    .foregroundStyle(.white)
            }
        }
    }

    // MARK: Header — current chapter

    private var headerCard: some View {
        VStack(alignment: .leading, spacing: RinklerSpacing.sm) {
            Text(current == nil ? "CHAPTER ZERO" : "CHAPTER \(romanOrNumber((current?.id ?? 0) + 1))")
                .font(RinklerFonts.caption)
                .tracking(2)
                .foregroundStyle(RinklerColors.auroraCyan)

            Text(current?.title ?? "Before First Light")
                .font(RinklerFonts.sans(34, .bold))
                .foregroundStyle(.white)

            Text(current?.narrative ?? "The sky is at its darkest. Protect one focus session to strike the first light.")
                .font(RinklerFonts.sans(16, .regular))
                .foregroundStyle(RinklerColors.white60)
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: RinklerSpacing.sm) {
                journeyStat("\(progress.lifetimeProtectedMinutes)", "min protected")
                journeyStat("\(progress.lifetimeSessions)", "sessions")
                journeyStat("\(progress.bestStreak)", "best streak")
            }
            .padding(.top, RinklerSpacing.xs)
        }
        .padding(RinklerSpacing.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RinklerColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .strokeBorder(RinklerColors.hairline, lineWidth: 1)
        )
    }

    private func journeyStat(_ value: String, _ label: String) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(RinklerFonts.statNumber)
                .foregroundStyle(.white)
            Text(label)
                .font(RinklerFonts.caption)
                .foregroundStyle(RinklerColors.white60)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, RinklerSpacing.sm)
        .background(RinklerColors.surfaceRaised)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    // MARK: Next chapter progress

    @ViewBuilder
    private var nextCard: some View {
        if let next {
            let frac = next.goal.fraction(progress)
            VStack(alignment: .leading, spacing: RinklerSpacing.sm) {
                Text("NEXT — \(next.title.uppercased())")
                    .font(RinklerFonts.caption)
                    .tracking(1.5)
                    .foregroundStyle(RinklerColors.white40)

                Text(next.goal.requirementText)
                    .font(RinklerFonts.sans(18, .semibold))
                    .foregroundStyle(.white)

                ProgressBar(fraction: frac)
                    .frame(height: 10)

                Text("\(Int(frac * 100))% there")
                    .font(RinklerFonts.caption)
                    .foregroundStyle(RinklerColors.auroraCyan)
            }
            .padding(RinklerSpacing.lg)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(RinklerColors.aurora.opacity(0.16))
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .strokeBorder(RinklerColors.auroraCyan.opacity(0.35), lineWidth: 1)
            )
        } else {
            VStack(alignment: .leading, spacing: RinklerSpacing.xs) {
                Text("THE SKY IS CLEAR")
                    .font(RinklerFonts.caption).tracking(2)
                    .foregroundStyle(RinklerColors.dawnGlow)
                Text("You've reached the final chapter. The dawn holds because you keep showing up.")
                    .font(RinklerFonts.sans(16, .regular))
                    .foregroundStyle(RinklerColors.white60)
            }
            .padding(RinklerSpacing.lg)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(RinklerColors.surface)
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        }
    }

    // MARK: All chapters

    private var chaptersList: some View {
        VStack(alignment: .leading, spacing: RinklerSpacing.sm) {
            Text("CHAPTERS")
                .font(RinklerFonts.caption).tracking(2)
                .foregroundStyle(RinklerColors.white40)
                .padding(.leading, RinklerSpacing.xs)
                .padding(.top, RinklerSpacing.sm)

            ForEach(Story.chapters) { chapter in
                chapterRow(chapter)
            }
        }
    }

    private func chapterRow(_ chapter: StoryChapter) -> some View {
        let unlocked = chapter.isUnlocked(progress)
        return HStack(alignment: .top, spacing: RinklerSpacing.md) {
            ZStack {
                Circle()
                    .fill(unlocked ? RinklerColors.auroraCyan : RinklerColors.surfaceRaised)
                    .frame(width: 34, height: 34)
                Image(systemName: unlocked ? "checkmark" : "lock.fill")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(unlocked ? .black.opacity(0.8) : RinklerColors.white40)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(chapter.title)
                    .font(RinklerFonts.sans(17, .semibold))
                    .foregroundStyle(unlocked ? .white : RinklerColors.white60)
                Text(unlocked ? chapter.narrative : chapter.goal.requirementText)
                    .font(RinklerFonts.sans(14, .regular))
                    .foregroundStyle(unlocked ? RinklerColors.white60 : RinklerColors.white40)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .padding(RinklerSpacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RinklerColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(unlocked ? RinklerColors.auroraCyan.opacity(0.3) : RinklerColors.hairline, lineWidth: 1)
        )
        .opacity(unlocked ? 1 : 0.75)
    }

    private func romanOrNumber(_ n: Int) -> String { "\(n)" }
}

/// Thin aurora-filled progress bar used on the journey screen.
private struct ProgressBar: View {
    let fraction: Double

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(RinklerColors.surfaceRaised)
                Capsule()
                    .fill(RinklerColors.aurora)
                    .frame(width: max(10, geo.size.width * max(0, min(1, fraction))))
            }
        }
    }
}

#Preview {
    NavigationStack {
        StoryJourneyView()
            .environmentObject(FocusSessionStore())
    }
    .preferredColorScheme(.dark)
}
