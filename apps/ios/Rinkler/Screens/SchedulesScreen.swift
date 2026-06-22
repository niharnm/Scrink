import SwiftUI

/// Story-aware recurring focus blocks (Opal "Smart Schedules" parity).
/// Lists the user's schedules and presents an editor sheet to create/edit them.
struct SchedulesScreen: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var store: ScheduleStore

    @State private var editing: FocusSchedule?
    @State private var showEditor = false

    var body: some View {
        ZStack {
            SkyBackgroundView(clarity: 0.3)

            ScrollView {
                VStack(alignment: .leading, spacing: RinklerSpacing.md) {
                    Text("Recurring focus blocks remind you and pre-fill a session — keep your evenings clear without thinking about it.")
                        .font(RinklerFonts.caption)
                        .foregroundStyle(RinklerColors.white60)
                        .padding(.top, RinklerSpacing.xs)

                    if store.schedules.isEmpty {
                        emptyState
                    } else {
                        ForEach(store.schedules) { schedule in
                            scheduleCard(schedule)
                        }
                    }

                    AuroraButton(title: "NEW SCHEDULE") {
                        editing = nil
                        showEditor = true
                    }
                    .padding(.top, RinklerSpacing.sm)
                }
                .padding(.horizontal, RinklerSpacing.lg)
                .padding(.bottom, RinklerSpacing.xxl)
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button { dismiss() } label: { BackArrowView() }
            }
            ToolbarItem(placement: .principal) {
                Text("SCHEDULES").font(RinklerFonts.headerTitle).foregroundStyle(.white)
            }
        }
        .sheet(isPresented: $showEditor) {
            ScheduleEditorSheet(schedule: editing) { result in
                if let result {
                    if store.schedules.contains(where: { $0.id == result.id }) {
                        store.update(result)
                    } else {
                        store.add(result)
                    }
                    store.requestNotificationAuthorization()
                }
                showEditor = false
            } onDelete: { sched in
                store.delete(sched)
                showEditor = false
            }
            .preferredColorScheme(.dark)
        }
    }

    private var emptyState: some View {
        VStack(spacing: RinklerSpacing.sm) {
            Image(systemName: "calendar.badge.clock")
                .font(.system(size: 38, weight: .light))
                .foregroundStyle(RinklerColors.auroraCyan)
            Text("No schedules yet")
                .font(RinklerFonts.coolvetica(size: 18))
                .foregroundStyle(.white)
            Text("Add one to auto-remind a daily focus block.")
                .font(RinklerFonts.caption)
                .foregroundStyle(RinklerColors.white60)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, RinklerSpacing.xl)
        .background(RinklerColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous).strokeBorder(RinklerColors.hairline, lineWidth: 1))
    }

    private func scheduleCard(_ schedule: FocusSchedule) -> some View {
        Button {
            editing = schedule
            showEditor = true
        } label: {
            HStack(spacing: RinklerSpacing.md) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(schedule.label.isEmpty ? "Focus block" : schedule.label)
                        .font(RinklerFonts.coolvetica(size: 18))
                        .foregroundStyle(.white)
                    Text("\(schedule.timeText) · \(schedule.weekdaysText) · \(schedule.durationText)")
                        .font(RinklerFonts.caption)
                        .foregroundStyle(RinklerColors.white60)
                }
                Spacer()
                Toggle("", isOn: Binding(
                    get: { schedule.isEnabled },
                    set: { _ in store.toggle(schedule) }
                ))
                .labelsHidden()
                .tint(RinklerColors.auroraCyan)
            }
            .padding(RinklerSpacing.md)
            .background(RinklerColors.surface)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .strokeBorder(schedule.isEnabled ? RinklerColors.auroraCyan.opacity(0.3) : RinklerColors.hairline, lineWidth: 1)
            )
            .opacity(schedule.isEnabled ? 1 : 0.6)
        }
    }
}

// MARK: - Editor

private struct ScheduleEditorSheet: View {
    let schedule: FocusSchedule?
    var onSave: (FocusSchedule?) -> Void
    var onDelete: (FocusSchedule) -> Void

    @State private var label: String
    @State private var weekdays: Set<Int>
    @State private var time: Date
    @State private var durationMinutes: Int
    @State private var strictness: FocusStrictness
    @State private var platforms: Set<FocusPlatform>

    private let durationOptions = [25, 45, 60, 90, 0]
    private let weekdaySymbols = Calendar.current.shortWeekdaySymbols

    init(schedule: FocusSchedule?, onSave: @escaping (FocusSchedule?) -> Void, onDelete: @escaping (FocusSchedule) -> Void) {
        self.schedule = schedule
        self.onSave = onSave
        self.onDelete = onDelete
        _label = State(initialValue: schedule?.label ?? "")
        _weekdays = State(initialValue: schedule?.weekdays ?? [2, 3, 4, 5, 6])
        var comps = DateComponents(); comps.hour = schedule?.hour ?? 20; comps.minute = schedule?.minute ?? 0
        _time = State(initialValue: Calendar.current.date(from: comps) ?? Date())
        _durationMinutes = State(initialValue: schedule?.durationMinutes ?? 45)
        _strictness = State(initialValue: schedule?.strictness ?? .focused)
        _platforms = State(initialValue: Set(schedule?.platforms ?? FocusPlatform.allCases))
    }

    var body: some View {
        NavigationStack {
            ZStack {
                SkyBackgroundView(clarity: 0.28)
                ScrollView {
                    VStack(alignment: .leading, spacing: RinklerSpacing.lg) {
                        field("NAME") {
                            TextField("", text: $label, prompt: Text("e.g. Evening wind-down").foregroundColor(RinklerColors.white40))
                                .font(RinklerFonts.coolvetica(size: 18))
                                .foregroundStyle(.white)
                                .tint(RinklerColors.auroraCyan)
                        }

                        field("REPEAT") {
                            HStack(spacing: 6) {
                                ForEach(1...7, id: \.self) { day in
                                    dayChip(day)
                                }
                            }
                        }

                        field("TIME") {
                            DatePicker("", selection: $time, displayedComponents: .hourAndMinute)
                                .labelsHidden()
                                .datePickerStyle(.compact)
                                .tint(RinklerColors.auroraCyan)
                        }

                        field("LENGTH") {
                            HStack(spacing: RinklerSpacing.sm) {
                                ForEach(durationOptions, id: \.self) { opt in
                                    pill(opt == 0 ? "Open" : "\(opt)m", selected: durationMinutes == opt) {
                                        durationMinutes = opt
                                    }
                                }
                            }
                        }

                        field("STRICTNESS") {
                            HStack(spacing: RinklerSpacing.sm) {
                                ForEach(FocusStrictness.allCases) { level in
                                    pill(level.title, selected: strictness == level) { strictness = level }
                                }
                            }
                        }

                        field("INTERRUPT") {
                            HStack(spacing: RinklerSpacing.sm) {
                                ForEach(FocusPlatform.allCases) { p in
                                    pill(p.title, selected: platforms.contains(p)) {
                                        if platforms.contains(p) { platforms.remove(p) } else { platforms.insert(p) }
                                    }
                                }
                            }
                        }

                        AuroraButton(title: "SAVE SCHEDULE", enabled: !weekdays.isEmpty && !platforms.isEmpty) {
                            save()
                        }

                        if let schedule {
                            GhostButton(title: "Delete", tint: RinklerColors.dawnGlow) { onDelete(schedule) }
                        }
                    }
                    .padding(RinklerSpacing.lg)
                }
            }
            .navigationTitle(schedule == nil ? "New schedule" : "Edit schedule")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { onSave(nil) }.foregroundStyle(.white)
                }
            }
        }
    }

    private func save() {
        let cal = Calendar.current
        let comps = cal.dateComponents([.hour, .minute], from: time)
        let result = FocusSchedule(
            id: schedule?.id ?? UUID(),
            label: label,
            weekdays: weekdays,
            hour: comps.hour ?? 20,
            minute: comps.minute ?? 0,
            durationMinutes: durationMinutes,
            strictness: strictness,
            platforms: Array(platforms),
            isEnabled: schedule?.isEnabled ?? true
        )
        onSave(result)
    }

    @ViewBuilder
    private func field<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: RinklerSpacing.sm) {
            Text(title).font(RinklerFonts.caption).tracking(1.5).foregroundStyle(RinklerColors.white40)
            content()
        }
        .padding(RinklerSpacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RinklerColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).strokeBorder(RinklerColors.hairline, lineWidth: 1))
    }

    private func dayChip(_ day: Int) -> some View {
        let on = weekdays.contains(day)
        return Button {
            if on { weekdays.remove(day) } else { weekdays.insert(day) }
        } label: {
            Text(String(weekdaySymbols[day - 1].prefix(1)))
                .font(RinklerFonts.coolvetica(size: 14))
                .foregroundStyle(on ? .black.opacity(0.85) : .white)
                .frame(width: 36, height: 36)
                .background(on ? AnyShapeStyle(RinklerColors.aurora) : AnyShapeStyle(RinklerColors.surfaceRaised))
                .clipShape(Circle())
        }
    }

    private func pill(_ title: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(RinklerFonts.coolvetica(size: 15))
                .foregroundStyle(selected ? .black.opacity(0.85) : .white)
                .padding(.horizontal, 16)
                .frame(height: 38)
                .background(selected ? AnyShapeStyle(RinklerColors.aurora) : AnyShapeStyle(RinklerColors.surfaceRaised))
                .clipShape(Capsule())
        }
    }
}

#Preview {
    NavigationStack {
        SchedulesScreen().environmentObject(ScheduleStore())
    }
    .preferredColorScheme(.dark)
}
