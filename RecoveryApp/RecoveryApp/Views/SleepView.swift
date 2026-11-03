import SwiftUI

public struct SleepView: View {
    @Bindable public var viewModel: TrainingModel
    @Environment(\.appHighContrast) private var appHighContrast
    private var sleepModel: SleepModel { viewModel.sleepModel }
    private var calendarModel: CalendarModel { viewModel.calendarModel }
    
    // Calendar Top-Down Drop-Down State
    @State private var isCalendarOpen: Bool = false
    
    // Time Picker Sheet State
    @State private var editingScheduleType: ScheduleEditType? = nil
    @State private var temporaryTimeSelection: Date = Date()
    
    // Checkmarks Management Sheet & Edit Alert State
    @State private var isCheckmarksSheetPresented: Bool = false
    @State private var newCheckmarkText: String = ""
    @State private var editingCheckmarkItem: SleepCheckmarkItem? = nil
    @State private var editingCheckmarkText: String = ""
    @State private var isEditSingleCheckmarkAlertPresented: Bool = false
    
    private enum ScheduleEditType: Identifiable {
        case inBed
        case asleep
        
        var id: Self { self }
        
        var title: String {
            switch self {
            case .inBed: return "Bedtime (In Bed)"
            case .asleep: return "Wake Up Time (Asleep)"
            }
        }
    }
    
    public init(viewModel: TrainingModel) {
        self.viewModel = viewModel
    }
    
    public var body: some View {
        ZStack(alignment: .top) {
            Color(uiColor: .systemGroupedBackground).ignoresSafeArea()
            
            // MARK: - Sleep Screen Scrollable Content
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 12) {
                    // MARK: - Header with Calendar Button in Top-Right Corner & Swipe Down Gesture
                    StandardHeaderView(
                        title: viewModel.sleepTitle,
                        dateSubtitle: calendarModel.currentDaySubtitle,
                        days: calendarModel.weekDays,
                        selectedDayIndex: calendarModel.selectedDayIndex,
                        showProfileButton: true, // Enables top-right corner action button
                        profileIconName: "calendar", // Renders calendar icon for date picker
                        onSelectDay: { index in
                            calendarModel.selectDay(at: index)
                            viewModel.selectDay(at: index)
                            sleepModel.selectDay(at: index)
                        },
                        onProfileTap: {
                            HapticManager.impact(.light)
                            withAppAnimation(.spring(response: 0.38, dampingFraction: 0.82)) {
                                isCalendarOpen.toggle()
                            }
                        }
                    )
                    .simultaneousGesture(
                        // Swipe gesture from top to bottom on header to reveal calendar
                        DragGesture(minimumDistance: 20)
                            .onEnded { value in
                                if value.translation.height > 40 && abs(value.translation.width) < 50 && !isCalendarOpen {
                                    HapticManager.impact(.medium)
                                    withAppAnimation(.spring(response: 0.38, dampingFraction: 0.82)) {
                                        isCalendarOpen = true
                                    }
                                }
                            }
                    )
                    
                    // Cards Container with Horizontal Margins
                    VStack(spacing: 12) {
                        // 1. Main Sleep Gauge & Bedtime Schedule Card
                        SleepCardView(
                            progress: sleepModel.ringProgress,
                            durationText: sleepModel.sleepDurationFormatted,
                            targetText: sleepModel.targetDurationFormatted,
                            accentColor: sleepModel.accentColor,
                            trackColor: sleepModel.trackColor,
                            inBedTime: sleepModel.inBedFullTimeFormatted,
                            asleepTime: sleepModel.asleepFullTimeFormatted,
                            onEditInBedTime: {
                                openTimeEditor(for: .inBed)
                            },
                            onEditAsleepTime: {
                                openTimeEditor(for: .asleep)
                            }
                        )
                        
                        // 2. Checkmarks Recommendation Section (Editable & Creatable)
                        SleepCheckmarksView(
                            sectionTitle: sleepModel.checkmarksSectionTitle,
                            recommendationNote: sleepModel.checkmarksSubtitle,
                            checkmarks: sleepModel.checkmarks,
                            accentColor: sleepModel.accentColor,
                            onToggle: { id in
                                sleepModel.toggleCheckmark(id: id)
                            },
                            onManageCheckmarks: {
                                isCheckmarksSheetPresented = true
                            },
                            onEditCheckmark: { item in
                                editingCheckmarkItem = item
                                editingCheckmarkText = item.title
                                isEditSingleCheckmarkAlertPresented = true
                            }
                        )
                    }
                    .padding(.horizontal, 20)
                    
                    // Breathing room above tab bar
                    Spacer()
                        .frame(height: 20)
                }
                .padding(.top, 4)
            }
            .scrollBounceBehavior(.always, axes: .vertical)
            .refreshable {
                await viewModel.syncHealthData(requireAuthentication: true)
            }
            
            // MARK: - Top-Down Drop-Down Calendar (Slides from Top to Bottom)
            if isCalendarOpen {
                // Dimmed Backdrop Overlay
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAppAnimation(.spring(response: 0.35, dampingFraction: 0.82)) {
                            isCalendarOpen = false
                        }
                    }
                    .transition(.opacity)
                
                // Calendar Panel Dropdown
                calendarDropDownView
                    .transition(
                        .asymmetric(
                            insertion: .move(edge: .top).combined(with: .opacity),
                            removal: .move(edge: .top).combined(with: .opacity)
                        )
                    )
                    .zIndex(100)
            }
        }
        // MARK: - Bedtime & Wake Time Picker Sheet
        .sheet(item: $editingScheduleType) { editType in
            timePickerSheet(for: editType)
                .presentationDetents([.height(300)])
                .presentationDragIndicator(.visible)
        }
        // MARK: - Checkmarks Management Sheet
        .sheet(isPresented: $isCheckmarksSheetPresented) {
            checkmarksManagerSheet
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
        // MARK: - Edit Single Checkmark Alert
        .alert("Edit Checkmark", isPresented: $isEditSingleCheckmarkAlertPresented) {
            TextField("Checkmark description", text: $editingCheckmarkText)
            
            Button("Save") {
                if let item = editingCheckmarkItem {
                    sleepModel.updateCheckmark(id: item.id, newTitle: editingCheckmarkText)
                }
            }
            
            Button("Delete", role: .destructive) {
                if let item = editingCheckmarkItem {
                    sleepModel.deleteCheckmark(id: item.id)
                }
            }
            
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Modify the text or delete this checkmark recommendation.")
        }
        // MARK: - Apple Health: reload the night every time the date or the data changes
        .task(id: healthReloadKey) {
            await loadSleepFromHealth()
        }
        .onAppear {
            sleepModel.checkAndPerformDailyResetIfNeeded()
            sleepModel.targetSleepHours = viewModel.sleepTargetHours
        }
    }
    
    // MARK: - Apple Health Sleep Loading
    private var healthReloadKey: String {
        let date = calendarModel.selectedDate.timeIntervalSince1970
        let sync = viewModel.health.lastSyncDate?.timeIntervalSince1970 ?? 0
        return "\(date)-\(sync)-\(viewModel.isAppleHealthConnected)"
    }
    
    private func loadSleepFromHealth() async {
        guard viewModel.isAppleHealthConnected else { return }
        let night = try? await viewModel.health.fetchSleepNight(endingOn: calendarModel.selectedDate)
        sleepModel.apply(night: night)
    }
    
    // MARK: - Calendar Drop-Down Panel View (Slides Down from Top)
    private var calendarDropDownView: some View {
        VStack(spacing: 12) {
            // Header Bar inside Dropdown
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Select Date")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.primary)
                    
                    Text(calendarModel.formattedHeaderTitle)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Jump to Today Pill Button
                Button {
                    HapticManager.impact(.light)
                    calendarModel.goToToday()
                    viewModel.selectDay(at: calendarModel.selectedDayIndex)
                    sleepModel.selectDay(at: calendarModel.selectedDayIndex)
                } label: {
                    HStack(spacing: 5) {
                        Image(systemName: "clock.arrow.circlepath")
                            .font(.system(size: 12, weight: .bold))
                        Text("Today")
                            .font(.system(size: 13, weight: .semibold))
                    }
                    .foregroundColor(sleepModel.accentColor)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(sleepModel.accentColor.opacity(0.12))
                    )
                }
                .buttonStyle(.plain)
                
                // Close Circle Button
                Button {
                    HapticManager.impact(.light)
                    withAppAnimation(.spring(response: 0.35, dampingFraction: 0.82)) {
                        isCalendarOpen = false
                    }
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(Color(uiColor: .tertiaryLabel))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 20)
            .padding(.top, 14)
            
            // Graphical Calendar DatePicker
            DatePicker(
                "Select Date",
                selection: Binding(
                    get: { calendarModel.selectedDate },
                    set: { newDate in
                        calendarModel.selectDate(newDate)
                        viewModel.selectDay(at: calendarModel.selectedDayIndex)
                        sleepModel.selectDay(at: calendarModel.selectedDayIndex)
                    }
                ),
                displayedComponents: [.date]
            )
            .datePickerStyle(.graphical)
            .tint(sleepModel.accentColor)
            .padding(.horizontal, 14)
            
            // Bottom Swipe Drag Handle Bar (Swipe down or up to dismiss)
            VStack(spacing: 4) {
                Capsule()
                    .fill(Color(uiColor: .systemGray3))
                    .frame(width: 40, height: 5)
                    .padding(.vertical, 8)
            }
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
            .gesture(
                DragGesture()
                    .onEnded { value in
                        if value.translation.height < -15 || value.translation.height > 35 {
                            HapticManager.impact(.light)
                            withAppAnimation(.spring(response: 0.35, dampingFraction: 0.82)) {
                                isCalendarOpen = false
                            }
                        }
                    }
            )
        }
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(Color(uiColor: .secondarySystemGroupedBackground))
                .shadow(color: Color.black.opacity(0.14), radius: 20, x: 0, y: 10)
        )
        .padding(.horizontal, 12)
        .padding(.top, 6)
    }
    
    // MARK: - Checkmarks Management Sheet
    private var checkmarksManagerSheet: some View {
        NavigationStack {
            List {
                // Section: Create New Checkmark
                Section(header: Text("Create New Checkmark")) {
                    HStack(spacing: 10) {
                        TextField("e.g. Turn off screens at 21:30", text: $newCheckmarkText)
                            .submitLabel(.done)
                            .onSubmit {
                                submitNewCheckmark()
                            }
                        
                        Button {
                            submitNewCheckmark()
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 22))
                                .foregroundColor(newCheckmarkText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? .gray : sleepModel.accentColor)
                        }
                        .disabled(newCheckmarkText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                    .padding(.vertical, 4)
                }
                
                // Section: Existing Checkmarks
                Section(header: Text("Existing Checkmarks (\(sleepModel.checkmarks.count))")) {
                    if sleepModel.checkmarks.isEmpty {
                        Text("No checkmarks. Add one above!")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                    } else {
                        ForEach(sleepModel.checkmarks) { item in
                            HStack(spacing: 12) {
                                // Checkbox icon
                                Image(systemName: item.isChecked ? "checkmark.circle.fill" : "circle")
                                    .font(.system(size: 18))
                                    .foregroundColor(item.isChecked ? sleepModel.accentColor : .secondary)
                                    .onTapGesture {
                                        sleepModel.toggleCheckmark(id: item.id)
                                    }
                                
                                // Checkmark Title Text
                                Text(item.title)
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundColor(.primary)
                                
                                Spacer()
                                
                                // Quick Edit Button
                                Button {
                                    editingCheckmarkItem = item
                                    editingCheckmarkText = item.title
                                    isEditSingleCheckmarkAlertPresented = true
                                } label: {
                                    Image(systemName: "pencil")
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundColor(Color(uiColor: .tertiaryLabel))
                                }
                                .buttonStyle(.borderless)
                            }
                            .padding(.vertical, 2)
                        }
                        .onDelete { indexSet in
                            sleepModel.deleteCheckmarks(at: indexSet)
                        }
                    }
                }
            }
            .navigationTitle("Manage Checkmarks")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    EditButton()
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        isCheckmarksSheetPresented = false
                    }
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(sleepModel.accentColor)
                }
            }
        }
    }
    
    private func submitNewCheckmark() {
        let trimmed = newCheckmarkText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        sleepModel.addCheckmark(title: trimmed)
        newCheckmarkText = ""
    }
    
    // MARK: - Interactive Time Picker Sheet
    private func openTimeEditor(for type: ScheduleEditType) {
        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month, .day], from: Date())
        
        let hour12 = (type == .inBed) ? sleepModel.inBedHour : sleepModel.asleepHour
        let minute = (type == .inBed) ? sleepModel.inBedMinute : sleepModel.asleepMinute
        let period = (type == .inBed) ? sleepModel.inBedPeriod : sleepModel.asleepPeriod
        
        var hour24 = hour12 % 12
        if period == .pm {
            hour24 += 12
        }
        
        components.hour = hour24
        components.minute = minute
        components.second = 0
        
        temporaryTimeSelection = calendar.date(from: components) ?? Date()
        editingScheduleType = type
    }
    
    private func timePickerSheet(for type: ScheduleEditType) -> some View {
        NavigationStack {
            VStack(spacing: 16) {
                DatePicker(
                    type.title,
                    selection: $temporaryTimeSelection,
                    displayedComponents: .hourAndMinute
                )
                .datePickerStyle(.wheel)
                .labelsHidden()
                
                Spacer()
            }
            .padding(.top, 8)
            .navigationTitle(type.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        editingScheduleType = nil
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveTimeSelection(for: type)
                        editingScheduleType = nil
                    }
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(sleepModel.accentColor)
                }
            }
        }
    }
    
    private func saveTimeSelection(for type: ScheduleEditType) {
        let calendar = Calendar.current
        let hour24 = calendar.component(.hour, from: temporaryTimeSelection)
        let minute = calendar.component(.minute, from: temporaryTimeSelection)
        
        let period: MeridiemPeriod = (hour24 >= 12) ? .pm : .am
        var hour12 = hour24 % 12
        if hour12 == 0 { hour12 = 12 }
        
        withAppAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            if type == .inBed {
                sleepModel.setInBed(hour: hour12, minute: minute, period: period)
            } else {
                sleepModel.setAsleep(hour: hour12, minute: minute, period: period)
            }
        }
        
        HapticManager.notification(.success)
    }
}

#Preview {
    SleepView(viewModel: TrainingModel())
}
