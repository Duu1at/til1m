import SwiftUI
import WidgetKit

// MARK: - Data model

struct TilimWidgetEntry: TimelineEntry {
    let date: Date
    let word: String
    let transcription: String
    let translation: String
    let translationKy: String
    let partOfSpeech: String
    let exampleEn: String
    let imagePath: String
    let audioUrl: String
    let learnedToday: Int
    let dailyGoal: Int
    let streakDays: Int
    let widgetState: String   // "learning" | "completed" | "review" | "empty"
    let wordId: String
    let level: String
    // Localised UI strings written by WidgetService — no hardcoded text in views.
    let completedTitle: String
    let progressText: String
    let streakText: String
    let labelReview: String
    let labelReviewBtn: String
    let labelEmpty: String

    static let placeholder = TilimWidgetEntry(
        date: Date(),
        word: "opportunity",
        transcription: "/ˌɒp.əˈtʃuː.nɪ.ti/",
        translation: "возможность",
        translationKy: "мүмкүнчүлүк",
        partOfSpeech: "noun",
        exampleEn: "This is a great opportunity.",
        imagePath: "",
        audioUrl: "",
        learnedToday: 3,
        dailyGoal: 5,
        streakDays: 7,
        widgetState: "learning",
        wordId: "",
        level: "B1",
        completedTitle: "✔ Отлично!",
        progressText: "3 из 5 слов",
        streakText: "🔥 7 дней подряд",
        labelReview: "Повторение",
        labelReviewBtn: "Повторить слова",
        labelEmpty: "Откройте TIl1m чтобы начать учить слова"
    )

    static let empty = TilimWidgetEntry(
        date: Date(),
        word: "",
        transcription: "",
        translation: "",
        translationKy: "",
        partOfSpeech: "",
        exampleEn: "",
        imagePath: "",
        audioUrl: "",
        learnedToday: 0,
        dailyGoal: 5,
        streakDays: 0,
        widgetState: "empty",
        wordId: "",
        level: "",
        completedTitle: "✔ Отлично!",
        progressText: "0 из 5 слов",
        streakText: "🔥 0 дней подряд",
        labelReview: "Повторение",
        labelReviewBtn: "Повторить слова",
        labelEmpty: "Откройте TIl1m чтобы начать учить слова"
    )
}

// MARK: - Provider

struct TilimWidgetProvider: TimelineProvider {

    private let defaults = UserDefaults(suiteName: "group.com.til1m.widget")

    func placeholder(in context: Context) -> TilimWidgetEntry {
        .placeholder
    }

    func getSnapshot(in context: Context, completion: @escaping (TilimWidgetEntry) -> Void) {
        completion(readEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<TilimWidgetEntry>) -> Void) {
        let entry = readEntry()
        let nextUpdate = Calendar.current.date(byAdding: .hour, value: 4, to: Date()) ?? Date()
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }

    // MARK: Helpers

    private func readEntry() -> TilimWidgetEntry {
        guard let d = defaults else { return .empty }
        let word = d.string(forKey: "word") ?? ""
        guard !word.isEmpty else { return .empty }

        return TilimWidgetEntry(
            date: Date(),
            word: word,
            transcription: d.string(forKey: "transcription") ?? "",
            translation: d.string(forKey: "translation") ?? "",
            translationKy: d.string(forKey: "translation_ky") ?? "",
            partOfSpeech: d.string(forKey: "part_of_speech") ?? "",
            exampleEn: d.string(forKey: "example_en") ?? "",
            imagePath: d.string(forKey: "image_path") ?? "",
            audioUrl: d.string(forKey: "audio_url") ?? "",
            learnedToday: d.integer(forKey: "learned_today"),
            dailyGoal: max(d.integer(forKey: "daily_goal"), 1),
            streakDays: d.integer(forKey: "streak_days"),
            widgetState: d.string(forKey: "widget_state") ?? "learning",
            wordId: d.string(forKey: "word_id") ?? "",
            level: d.string(forKey: "level") ?? "",
            completedTitle: d.string(forKey: "completed_title") ?? "✔",
            progressText: d.string(forKey: "progress_text") ?? "",
            streakText: d.string(forKey: "streak_text") ?? "",
            labelReview: d.string(forKey: "label_review") ?? "Review",
            labelReviewBtn: d.string(forKey: "label_review_btn") ?? "Review",
            labelEmpty: d.string(forKey: "label_empty") ?? ""
        )
    }
}

// MARK: - Colors & helpers

private extension Color {
    static let widgetBg       = Color(.sRGB, red: 1,    green: 1,    blue: 1,    opacity: 1)
    static let widgetBgReview = Color(.sRGB, red: 1,    green: 0.95, blue: 0.88, opacity: 1)
    static let textPrimary    = Color(.sRGB, red: 0.07, green: 0.09, blue: 0.15, opacity: 1)
    static let textSecondary  = Color(.sRGB, red: 0.42, green: 0.45, blue: 0.50, opacity: 1)
    static let progressBlue   = Color(.sRGB, red: 0.12, green: 0.31, blue: 0.55, opacity: 1)
    static let progressGreen  = Color(.sRGB, red: 0.30, green: 0.69, blue: 0.31, opacity: 1)
    static let progressTrack  = Color(.sRGB, red: 0.88, green: 0.88, blue: 0.88, opacity: 1)
    static let badgeBg        = Color(.sRGB, red: 0.91, green: 0.91, blue: 0.96, opacity: 1)
    static let badgeText      = Color(.sRGB, red: 0.21, green: 0.19, blue: 0.63, opacity: 1)
    static let streakOrange   = Color(.sRGB, red: 0.85, green: 0.47, blue: 0.04, opacity: 1)
}

private func progressFill(for entry: TilimWidgetEntry) -> Double {
    guard entry.dailyGoal > 0 else { return 0 }
    if entry.widgetState == "completed" { return 1 }
    return min(Double(entry.learnedToday) / Double(entry.dailyGoal), 1)
}

private func progressColor(for state: String) -> Color {
    state == "completed" ? .progressGreen : .progressBlue
}

private func widgetBackground(for state: String) -> Color {
    state == "review" ? .widgetBgReview : .widgetBg
}

// Safe constant: the literal "til1m://home" always produces a valid URL.
private let kFallbackDeepLink = URL(string: "til1m://home")!

private func deepLink(_ uri: String) -> URL {
    URL(string: uri) ?? kFallbackDeepLink
}

// MARK: - Small view (systemSmall)

struct TilimSmallView: View {
    let entry: TilimWidgetEntry

    var body: some View {
        ZStack {
            widgetBackground(for: entry.widgetState)
            if entry.widgetState == "empty" {
                emptyView
            } else if entry.widgetState == "completed" {
                completedSmallView
            } else {
                learningSmallView
            }
        }
        .widgetURL(deepLink("til1m://word?id=\(entry.wordId)"))
    }

    private var emptyView: some View {
        Text(entry.labelEmpty)
            .font(.system(size: 12))
            .foregroundColor(.textSecondary)
            .multilineTextAlignment(.center)
            .padding()
    }

    private var completedSmallView: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(entry.completedTitle)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.textPrimary)
            Text(entry.streakText)
                .font(.system(size: 13))
                .foregroundColor(.streakOrange)
        }
        .padding(14)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    }

    private var learningSmallView: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(entry.word)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.textPrimary)
                .lineLimit(1)
            if !entry.transcription.isEmpty {
                Text(entry.transcription)
                    .font(.system(size: 12))
                    .foregroundColor(.textSecondary)
                    .lineLimit(1)
            }
            Text(entry.translation)
                .font(.system(size: 14))
                .foregroundColor(.textPrimary)
                .lineLimit(1)
        }
        .padding(14)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    }
}

// MARK: - Medium view (systemMedium)

struct TilimMediumView: View {
    let entry: TilimWidgetEntry

    var body: some View {
        ZStack {
            widgetBackground(for: entry.widgetState)
            if entry.widgetState == "empty" {
                Text(entry.labelEmpty)
                    .font(.system(size: 12))
                    .foregroundColor(.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding()
            } else {
                mediumContent
            }
        }
    }

    private var mediumContent: some View {
        HStack(alignment: .center, spacing: 12) {
            // Left: word info + progress
            VStack(alignment: .leading, spacing: 4) {
                if entry.widgetState == "review" {
                    Text(entry.labelReview)
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(.badgeText)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color.badgeBg)
                        .cornerRadius(6)
                }

                Link(destination: deepLink("til1m://word?id=\(entry.wordId)")) {
                    Text(entry.widgetState == "completed" ? entry.completedTitle : entry.word)
                        .font(.system(size: 17, weight: .bold))
                        .foregroundColor(.textPrimary)
                        .lineLimit(1)
                }

                HStack(spacing: 4) {
                    Text(entry.transcription)
                        .font(.system(size: 11))
                        .foregroundColor(.textSecondary)
                        .lineLimit(1)
                    Link(destination: deepLink("til1m://audio?id=\(entry.wordId)&url=\(entry.audioUrl)")) {
                        Text("🔊").font(.system(size: 14))
                    }
                }

                Text(entry.widgetState == "completed" ? entry.streakText : entry.translation)
                    .font(.system(size: 13))
                    .foregroundColor(entry.widgetState == "completed" ? .streakOrange : .textPrimary)
                    .lineLimit(1)

                // Progress bar
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.progressTrack)
                            .frame(height: 6)
                        RoundedRectangle(cornerRadius: 4)
                            .fill(progressColor(for: entry.widgetState))
                            .frame(
                                width: geo.size.width * progressFill(for: entry),
                                height: 6
                            )
                    }
                }
                .frame(height: 6)
                .padding(.top, 4)

                Text(entry.progressText)
                    .font(.system(size: 10))
                    .foregroundColor(.textSecondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            // Right: image placeholder (real image loading requires file URL)
            if !entry.imagePath.isEmpty {
                AsyncImage(url: URL(fileURLWithPath: entry.imagePath)) { phase in
                    if let img = phase.image {
                        img.resizable()
                            .scaledToFill()
                            .frame(width: 80, height: 80)
                            .clipped()
                            .cornerRadius(10)
                    } else {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.badgeBg)
                            .frame(width: 80, height: 80)
                    }
                }
            }
        }
        .padding(14)
    }
}

// MARK: - Large view (systemLarge)

struct TilimLargeView: View {
    let entry: TilimWidgetEntry

    var body: some View {
        ZStack {
            widgetBackground(for: entry.widgetState)
            if entry.widgetState == "empty" {
                Text(entry.labelEmpty)
                    .font(.system(size: 13))
                    .foregroundColor(.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding()
            } else {
                largeContent
            }
        }
    }

    private var largeContent: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Review label
            if entry.widgetState == "review" {
                Text(entry.labelReview)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.badgeText)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color.badgeBg)
                    .cornerRadius(6)
            }

            // Word + part of speech
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Link(destination: deepLink("til1m://word?id=\(entry.wordId)")) {
                    Text(entry.widgetState == "completed" ? entry.completedTitle : entry.word)
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(.textPrimary)
                        .lineLimit(1)
                }
                if !entry.partOfSpeech.isEmpty && entry.widgetState == "learning" {
                    Text(entry.partOfSpeech)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.badgeText)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color.badgeBg)
                        .cornerRadius(6)
                }
            }

            // Image
            if !entry.imagePath.isEmpty {
                AsyncImage(url: URL(fileURLWithPath: entry.imagePath)) { phase in
                    if let img = phase.image {
                        img.resizable()
                            .scaledToFill()
                            .frame(maxWidth: .infinity)
                            .frame(height: 110)
                            .clipped()
                            .cornerRadius(10)
                    } else {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.badgeBg)
                            .frame(maxWidth: .infinity)
                            .frame(height: 110)
                    }
                }
            }

            // Transcription + audio
            HStack(spacing: 4) {
                Text(entry.transcription)
                    .font(.system(size: 12))
                    .foregroundColor(.textSecondary)
                Link(destination: deepLink("til1m://audio?id=\(entry.wordId)&url=\(entry.audioUrl)")) {
                    Text("🔊").font(.system(size: 16))
                }
            }

            // Translation
            Text(entry.widgetState == "completed" ? entry.streakText : entry.translation)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(entry.widgetState == "completed" ? .streakOrange : .textPrimary)
                .lineLimit(2)

            // Example
            if !entry.exampleEn.isEmpty && entry.widgetState == "learning" {
                Text("«\(entry.exampleEn)»")
                    .font(.system(size: 11))
                    .italic()
                    .foregroundColor(.textSecondary)
                    .lineLimit(2)
            }

            Spacer()

            // Progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.progressTrack)
                        .frame(height: 7)
                    RoundedRectangle(cornerRadius: 4)
                        .fill(progressColor(for: entry.widgetState))
                        .frame(
                            width: geo.size.width * progressFill(for: entry),
                            height: 7
                        )
                }
            }
            .frame(height: 7)

            // Progress text + streak
            HStack {
                Link(destination: deepLink("til1m://home")) {
                    Text(entry.progressText)
                        .font(.system(size: 11))
                        .foregroundColor(.textSecondary)
                }
                Spacer()
                Text(entry.streakText)
                    .font(.system(size: 11))
                    .foregroundColor(.streakOrange)
            }

            // Review button (completed + review states)
            if entry.widgetState == "completed" || entry.widgetState == "review" {
                Link(destination: deepLink("til1m://review")) {
                    Text(entry.labelReviewBtn)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.badgeText)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(Color.badgeBg)
                        .cornerRadius(8)
                }
            }
        }
        .padding(16)
    }
}

// MARK: - Widget entry point

struct TilimWidget: Widget {
    let kind = "TilimWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: TilimWidgetProvider()) { entry in
            TilimWidgetEntryView(entry: entry)
                .containerBackground(.clear, for: .widget)
        }
        .configurationDisplayName("TIl1m")
        .description("Слово дня и прогресс обучения")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

// MARK: - Entry view dispatcher

struct TilimWidgetEntryView: View {
    @Environment(\.widgetFamily) var family
    let entry: TilimWidgetEntry

    var body: some View {
        switch family {
        case .systemSmall:
            TilimSmallView(entry: entry)
        case .systemMedium:
            TilimMediumView(entry: entry)
        case .systemLarge:
            TilimLargeView(entry: entry)
        default:
            TilimSmallView(entry: entry)
        }
    }
}

// MARK: - Preview

#Preview(as: .systemSmall) {
    TilimWidget()
} timeline: {
    TilimWidgetEntry.placeholder
}

#Preview(as: .systemMedium) {
    TilimWidget()
} timeline: {
    TilimWidgetEntry.placeholder
}

#Preview(as: .systemLarge) {
    TilimWidget()
} timeline: {
    TilimWidgetEntry.placeholder
}
