import SwiftUI
import AuthenticationServices
import PhotosUI

public struct ProfileView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @Bindable public var viewModel: TrainingModel
    
    // Active sheet for interactive editing
    @State private var activeSheet: ActiveProfileSheet? = nil
    
    // Photo picker state
    @State private var selectedPhotoItem: PhotosPickerItem? = nil
    
    // Name editing state
    @State private var isEditingNameAlert: Bool = false
    @State private var newNameDraft: String = ""
    
    // Custom sport entry state inside Sport Type sheet
    @State private var isAddingCustomSport: Bool = false
    @State private var customSportDraft: String = ""
    
    // Selection state variables for all vertical wheel pickers
    @State private var selectedSportType: String = "Running"
    @State private var selectedTrainingLevel: String = "Advanced"
    @State private var selectedFrequency: String = "3"
    @State private var selectedGender: String = "Female"
    @State private var weightWholeKg: Int = 56
    @State private var weightDecimal: Int = 0
    @State private var selectedHeightCm: Int = 165
    
    // Apple Health & Apple ID synchronization state & sheets
    @State private var isRemoveSyncConfirmationPresented: Bool = false
    @State private var isHealthAccessSheetPresented: Bool = false
    
    // HealthKit permissions individual toggles (Official Apple Health Access style)
    @State private var allowWriteWorkouts: Bool = true
    @State private var allowReadSleep: Bool = true
    @State private var allowReadWorkouts: Bool = true
    @State private var allowReadHeartRate: Bool = true
    @State private var allowReadHRV: Bool = true
    @State private var allowReadBodyMass: Bool = true
    @State private var allowReadBiologicalSex: Bool = true
    @State private var allowReadActiveEnergy: Bool = true
    
    private var allPermissionsEnabled: Bool {
        allowWriteWorkouts && allowReadSleep && allowReadWorkouts && allowReadHeartRate && allowReadHRV && allowReadBodyMass && allowReadBiologicalSex && allowReadActiveEnergy
    }
    
    public init(viewModel: TrainingModel) {
        self.viewModel = viewModel
    }
    
    public var body: some View {
        NavigationStack {
            ZStack {
                Color(uiColor: .systemGroupedBackground)
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // MARK: - Custom Top Bar with Circular Back Button `<`
                    topNavBar
                    
                    ScrollView(.vertical, showsIndicators: false) {
                        VStack(spacing: 20) {
                            // MARK: - Profile Header (Native SwiftUI Avatar + Username)
                            profileHeaderSection
                            
                            // MARK: - Section: YOUR SPORT
                            yourSportSection
                            
                            // MARK: - Section: ABOUT YOU
                            aboutYouSection
                            
                            // MARK: - Footer (Sign in with Apple + Info)
                            footerSection
                            
                            Spacer().frame(height: 24)
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 8)
                    }
                }
            }
            .navigationBarHidden(true)
        }
        // Name Editing Alert
        .alert("Edit Your Name", isPresented: $isEditingNameAlert) {
            TextField("Name", text: $newNameDraft)
            Button("Cancel", role: .cancel) {}
            Button("Save") {
                viewModel.updateUserName(newNameDraft)
            }
        } message: {
            Text("Enter the name you'd like displayed on your profile.")
        }
        // Interactive Editing Bottom Sheets with Vertical Wheel Pickers
        .sheet(item: $activeSheet) { sheet in
            sheetContent(for: sheet)
                .presentationDetents(sheet.detents)
                .presentationDragIndicator(.visible)
                .presentationBackground(Color(uiColor: .systemBackground))
        }
        // Native Apple Health Access Permission Sheet
        .sheet(isPresented: $isHealthAccessSheetPresented) {
            healthAccessSheet
        }
        // Handle PhotosPicker photo selection
        .onChange(of: selectedPhotoItem) { _, newItem in
            Task {
                if let data = try? await newItem?.loadTransferable(type: Data.self) {
                    viewModel.updateProfileCustomImageData(data)
                }
            }
        }
    }
    
    // MARK: - Top Navigation Bar
    private var topNavBar: some View {
        HStack {
            Button {
                HapticManager.impact(.light)
                dismiss()
                viewModel.isProfilePresented = false
            } label: {
                ZStack {
                    Circle()
                        .fill(Color(uiColor: .secondarySystemGroupedBackground))
                        .shadow(color: Color.black.opacity(0.06), radius: 6, x: 0, y: 2)
                        .frame(width: 38, height: 38)
                    
                    Image(systemName: "chevron.left")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.primary)
                }
            }
            .accessibilityLabel("Go back")
            
            Spacer()
            
            // Settings Button
            NavigationLink {
                SettingsView(viewModel: viewModel)
            } label: {
                ZStack {
                    Circle()
                        .fill(Color(uiColor: .secondarySystemGroupedBackground))
                        .shadow(color: Color.black.opacity(0.06), radius: 6, x: 0, y: 2)
                        .frame(width: 38, height: 38)
                    
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.primary)
                }
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Settings")
        }
        .padding(.horizontal, 20)
        .padding(.top, 10)
        .padding(.bottom, 2)
    }
    
    // MARK: - Profile Header Section (Profile Photo + Username)
    private var profileHeaderSection: some View {
        VStack(spacing: 10) {
            Text(viewModel.profileTitle)
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.primary)
                .multilineTextAlignment(.center)
            
            // Centered Circular Profile Photo (Tap to change photo via PhotosPicker)
            PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                ZStack(alignment: .bottomTrailing) {
                    if let data = viewModel.profileCustomImageData, let uiImage = UIImage(data: data) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 88, height: 88)
                            .clipShape(Circle())
                            .shadow(color: Color.black.opacity(0.12), radius: 8, x: 0, y: 3)
                    } else {
                        Image("blank_avatar")
                            .resizable()
                            .scaledToFill()
                            .frame(width: 88, height: 88)
                            .clipShape(Circle())
                            .shadow(color: Color.black.opacity(0.08), radius: 6, x: 0, y: 2)
                    }
                    
                    // Edit pencil indicator badge
                    ZStack {
                        Circle()
                            .fill(Color(uiColor: .secondarySystemGroupedBackground))
                            .frame(width: 26, height: 26)
                            .shadow(color: Color.black.opacity(0.15), radius: 4, x: 0, y: 2)
                        
                        Image(systemName: "pencil")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.primary)
                    }
                    .offset(x: 2, y: 2)
                }
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Change profile photo")
            .contextMenu {
                if viewModel.profileCustomImageData != nil {
                    Button(role: .destructive) {
                        viewModel.updateProfileCustomImageData(nil)
                        selectedPhotoItem = nil
                    } label: {
                        Label("Remove Photo", systemImage: "trash")
                    }
                }
                Button {
                    activeSheet = .avatar
                } label: {
                    Label("Customize Icon", systemImage: "paintpalette")
                }
            }
            
            // Username (Tap to Edit)
            Button {
                newNameDraft = (viewModel.userName == "-" ? "" : viewModel.userName)
                isEditingNameAlert = true
            } label: {
                HStack(spacing: 6) {
                    Text(viewModel.userName)
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(viewModel.userName == "-" ? .secondary : .primary)
                    
                    Image(systemName: "pencil")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.secondary)
                }
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Edit user name")
        }
        .padding(.top, 2)
    }
    
    // MARK: - Section: YOUR SPORT (All Vertical Wheel Pickers)
    private var yourSportSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("YOUR SPORT")
                .font(.system(size: 12.5, weight: .bold))
                .foregroundColor(.secondary)
                .padding(.horizontal, 4)
            
            VStack(spacing: 0) {
                ProfileRowView(
                    iconName: "figure.run",
                    iconColor: .blue,
                    title: "Sport Type",
                    value: viewModel.sportType,
                    showDivider: true,
                    onTap: {
                        selectedSportType = (viewModel.sportType == "-" ? (ProfileOptions.sports.first ?? "Running") : viewModel.sportType)
                        activeSheet = .sportType
                    }
                )
                
                ProfileRowView(
                    iconName: "chart.bar.fill",
                    iconColor: .blue,
                    title: "Training Level",
                    value: viewModel.trainingLevel,
                    showDivider: true,
                    onTap: {
                        selectedTrainingLevel = (viewModel.trainingLevel == "-" ? (ProfileOptions.trainingLevels.first ?? "Advanced") : viewModel.trainingLevel)
                        activeSheet = .trainingLevel
                    }
                )
                
                ProfileRowView(
                    iconName: "calendar",
                    iconColor: .blue,
                    title: "Weekly Frequency",
                    value: viewModel.weeklyFrequency,
                    showDivider: false,
                    onTap: {
                        syncCurrentFrequency()
                        activeSheet = .weeklyFrequency
                    }
                )
            }
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Color(uiColor: .secondarySystemGroupedBackground))
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(Color(uiColor: .separator).opacity(0.25), lineWidth: 0.5)
                    )
                    .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 2)
            )
        }
    }
    
    // MARK: - Section: ABOUT YOU (All Vertical Wheel Pickers)
    private var aboutYouSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("ABOUT YOU")
                .font(.system(size: 12.5, weight: .bold))
                .foregroundColor(.secondary)
                .padding(.horizontal, 4)
            
            VStack(spacing: 0) {
                ProfileRowView(
                    iconName: "person.fill",
                    iconColor: .blue,
                    title: "Gender",
                    value: viewModel.gender,
                    showDivider: true,
                    onTap: {
                        selectedGender = (viewModel.gender == "-" ? (ProfileOptions.genders.first ?? "Female") : viewModel.gender)
                        activeSheet = .gender
                    }
                )
                
                ProfileRowView(
                    iconName: "scalemass.fill",
                    iconColor: .blue,
                    title: "Weight",
                    value: viewModel.weight,
                    showDivider: true,
                    onTap: {
                        parseWeightNumber()
                        activeSheet = .weight
                    }
                )
                
                ProfileRowView(
                    iconName: "ruler.fill",
                    iconColor: .blue,
                    title: "Height",
                    value: viewModel.height,
                    showDivider: false,
                    onTap: {
                        parseHeightNumber()
                        activeSheet = .height
                    }
                )
            }
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Color(uiColor: .secondarySystemGroupedBackground))
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(Color(uiColor: .separator).opacity(0.25), lineWidth: 0.5)
                    )
                    .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 2)
            )
        }
    }
    
    // MARK: - Footer Section (Official "Sign in with Apple" Badge)
    private var footerSection: some View {
        VStack(spacing: 12) {
            if viewModel.isAppleIdSignedIn {
                // Synchronized State: Premium Apple Badge showing active synchronization
                Button {
                    HapticManager.impact(.light)
                    Task {
                        await viewModel.syncHealthData(requireAuthentication: true)
                    }
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "apple.logo")
                            .font(.system(size: 20, weight: .semibold))
                            .offset(y: -1)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Synchronized with Apple")
                                .font(.system(size: 15, weight: .semibold))
                            
                            Text("Apple Health & Apple ID active")
                                .font(.system(size: 11, weight: .regular))
                                .opacity(0.8)
                        }
                        
                        Spacer()
                        
                        if viewModel.health.isSyncing {
                            ProgressView()
                                .tint(colorScheme == .dark ? Color.black : Color.white)
                        } else {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(.green)
                        }
                    }
                    .padding(.horizontal, 18)
                    .foregroundColor(colorScheme == .dark ? Color.black : Color.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(colorScheme == .dark ? Color.white : Color.black)
                            .shadow(color: Color.black.opacity(0.12), radius: 6, x: 0, y: 2)
                    )
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Apple synchronization active. Tap to sync now.")
                
                // Option to remove synchronization
                Button(role: .destructive) {
                    HapticManager.impact(.light)
                    isRemoveSyncConfirmationPresented = true
                } label: {
                    HStack(spacing: 5) {
                        Image(systemName: "link.badge.minus")
                            .font(.system(size: 13, weight: .semibold))
                        Text("Remove synchronization")
                            .font(.system(size: 13, weight: .medium))
                    }
                    .foregroundColor(.red)
                    .padding(.top, 2)
                }
                .buttonStyle(.plain)
            } else {
                // Official Native "Sign in with Apple" Badge
                // Standard 12pt corner radius, adapts to Dark Mode (white badge) and Light Mode (black badge)
                SignInWithAppleButton(
                    .signIn,
                    onRequest: { request in
                        request.requestedScopes = [.fullName, .email]
                    },
                    onCompletion: { result in
                        viewModel.handleSignInWithApple(result: result)
                        isHealthAccessSheetPresented = true
                    }
                )
                .signInWithAppleButtonStyle(colorScheme == .dark ? .white : .black)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .cornerRadius(12)
                .shadow(color: Color.black.opacity(0.12), radius: 6, x: 0, y: 2)
            }
            
            Text(viewModel.appleHealthNotice)
                .font(.system(size: 12, weight: .regular))
                .foregroundColor(viewModel.isAppleHealthConnected ? .green : .secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 16)
                .animation(.easeInOut(duration: 0.25), value: viewModel.isAppleHealthConnected)
        }
        .padding(.top, 8)
        .confirmationDialog(
            "Remove Synchronization",
            isPresented: $isRemoveSyncConfirmationPresented,
            titleVisibility: .visible
        ) {
            Button("Remove Synchronization", role: .destructive) {
                viewModel.removeHealthSync()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Do you want to disconnect Sign in with Apple and Apple Health synchronization?")
        }
    }
    
    // MARK: - Native Apple Health Access Permission Sheet
    private var healthAccessSheet: some View {
        NavigationStack {
            List {
                // Header Information Section
                Section {
                    VStack(alignment: .center, spacing: 14) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(Color.white)
                                .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 3)
                                .frame(width: 60, height: 60)
                            
                            Image(systemName: "heart.fill")
                                .font(.system(size: 30, weight: .semibold))
                                .foregroundColor(.pink)
                        }
                        .padding(.top, 6)
                        
                        Text("“Hushtide” would like to access and update your Health data in order to calculate your daily readiness and sync workouts.")
                            .font(.system(size: 14, weight: .regular))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 4)
                    }
                    .frame(maxWidth: .infinity)
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 12, trailing: 0))
                }
                
                // Turn On All Section
                Section {
                    HStack {
                        Text("Turn On All")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.primary)
                        Spacer()
                        Button(allPermissionsEnabled ? "Turn Off All" : "Turn On All") {
                            let newState = !allPermissionsEnabled
                            allowWriteWorkouts = newState
                            allowReadSleep = newState
                            allowReadWorkouts = newState
                            allowReadHeartRate = newState
                            allowReadHRV = newState
                            allowReadBodyMass = newState
                            allowReadBiologicalSex = newState
                            allowReadActiveEnergy = newState
                        }
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.blue)
                    }
                }
                
                // WRITE Data Section
                Section(header: Text("ALLOW “RECOVERYAPP” TO WRITE:")) {
                    healthToggleRow(icon: "figure.run", color: .blue, title: "Workouts", isOn: $allowWriteWorkouts)
                }
                
                // READ Data Section
                Section(header: Text("ALLOW “RECOVERYAPP” TO READ:")) {
                    healthToggleRow(icon: "bed.double.fill", color: Color(red: 88/255, green: 86/255, blue: 215/255), title: "Sleep Analysis", isOn: $allowReadSleep)
                    healthToggleRow(icon: "figure.run", color: .blue, title: "Workouts", isOn: $allowReadWorkouts)
                    healthToggleRow(icon: "heart.fill", color: .red, title: "Resting Heart Rate", isOn: $allowReadHeartRate)
                    healthToggleRow(icon: "waveform.path.ecg", color: .pink, title: "Heart Rate Variability", isOn: $allowReadHRV)
                    healthToggleRow(icon: "scalemass.fill", color: .orange, title: "Weight & Height", isOn: $allowReadBodyMass)
                    healthToggleRow(icon: "person.fill", color: .purple, title: "Biological Sex", isOn: $allowReadBiologicalSex)
                    healthToggleRow(icon: "flame.fill", color: .red, title: "Active Energy", isOn: $allowReadActiveEnergy)
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Health Access")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Don't Allow") {
                        isHealthAccessSheetPresented = false
                    }
                    .foregroundColor(.blue)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Allow") {
                        HapticManager.notification(.success)
                        Task {
                            await viewModel.connectAppleHealth()
                            isHealthAccessSheetPresented = false
                        }
                    }
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.blue)
                }
            }
        }
    }
    
    private func healthToggleRow(icon: String, color: Color, title: String, isOn: Binding<Bool>) -> some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 7, style: .continuous)
                    .fill(color)
                    .frame(width: 28, height: 28)
                Image(systemName: icon)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)
            }
            Text(title)
                .font(.system(size: 16, weight: .regular))
                .foregroundColor(.primary)
            Spacer()
            Toggle("", isOn: isOn)
                .labelsHidden()
        }
    }
    
    // MARK: - Sheet Builder for Interactive Vertical Wheel Pickers
    @ViewBuilder
    private func sheetContent(for sheet: ActiveProfileSheet) -> some View {
        NavigationStack {
            VStack(spacing: 0) {
                switch sheet {
                case .avatar:
                    avatarCustomizationView
                case .sportType:
                    wheelPickerSheetView(
                        title: "Sport Type",
                        subtitle: "Select your sport discipline",
                        options: viewModel.allAvailableSports,
                        selection: $selectedSportType,
                        onSave: { val in
                            viewModel.updateSportType(val)
                        },
                        extraActionTitle: "Add Sport",
                        onExtraAction: {
                            customSportDraft = ""
                            isAddingCustomSport = true
                        }
                    )
                case .trainingLevel:
                    wheelPickerSheetView(
                        title: "Training Level",
                        subtitle: "Select your experience level",
                        options: ProfileOptions.trainingLevels,
                        selection: $selectedTrainingLevel,
                        onSave: { val in
                            viewModel.updateTrainingLevel(val)
                        }
                    )
                case .weeklyFrequency:
                    frequencyWheelPickerView
                case .gender:
                    wheelPickerSheetView(
                        title: "Gender",
                        subtitle: "Select your gender identity",
                        options: ProfileOptions.genders,
                        selection: $selectedGender,
                        onSave: { val in
                            viewModel.updateGender(val)
                        }
                    )
                case .weight:
                    weightDoubleWheelPickerView
                case .height:
                    numericWheelPickerSheetView(
                        title: "Height",
                        subtitle: "Scroll to select your height",
                        unit: "cm",
                        range: 120...225,
                        selection: $selectedHeightCm,
                        onSave: { val in
                            viewModel.updateHeight("\(val)cm")
                        }
                    )
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        saveCurrentSheetSelection()
                        activeSheet = nil
                    }
                    .font(.system(size: 16, weight: .semibold))
                }
            }
            .alert("Add New Sport", isPresented: $isAddingCustomSport) {
                TextField("Sport name (e.g. Boxing, Tennis)", text: $customSportDraft)
                Button("Cancel", role: .cancel) {
                    customSportDraft = ""
                }
                Button("Add") {
                    let trimmed = customSportDraft.trimmingCharacters(in: .whitespacesAndNewlines)
                    if !trimmed.isEmpty {
                        viewModel.addCustomSport(trimmed)
                        selectedSportType = trimmed
                    }
                    customSportDraft = ""
                }
            } message: {
                Text("Enter the name of your sport discipline.")
            }
        }
    }
    
    // MARK: - Generic Text Wheel Picker
    @ViewBuilder
    private func wheelPickerSheetView(
        title: String,
        subtitle: String,
        options: [String],
        selection: Binding<String>,
        onSave: @escaping (String) -> Void,
        extraActionTitle: String? = nil,
        onExtraAction: (() -> Void)? = nil
    ) -> some View {
        VStack(spacing: 10) {
            Text(subtitle)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.secondary)
                .padding(.top, 10)
            
            // Native Vertical Scrolling Wheel Picker
            Picker("", selection: selection) {
                ForEach(options, id: \.self) { item in
                    Text(item)
                        .font(.system(size: 20, weight: .medium, design: .rounded))
                        .tag(item)
                }
            }
            .pickerStyle(.wheel)
            .frame(height: 120)
            .clipped()
            .padding(.horizontal, 20)
            
            if let extraTitle = extraActionTitle, let action = onExtraAction {
                Button {
                    action()
                } label: {
                    HStack(spacing: 5) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 14))
                        Text(extraTitle)
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .foregroundColor(.blue)
                }
                .buttonStyle(.plain)
                .padding(.vertical, 2)
            }
            
            Button {
                onSave(selection.wrappedValue)
                activeSheet = nil
            } label: {
                Text("Confirm")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 46)
                    .background(
                        Capsule()
                            .fill(Color.blue)
                    )
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 24)
            .padding(.bottom, 10)
            
            Spacer()
        }
        .navigationTitle(title)
    }
    
    // MARK: - Numeric Wheel Picker (Weight & Height)
    @ViewBuilder
    private func numericWheelPickerSheetView(
        title: String,
        subtitle: String,
        unit: String,
        range: ClosedRange<Int>,
        selection: Binding<Int>,
        onSave: @escaping (Int) -> Void
    ) -> some View {
        VStack(spacing: 12) {
            Text(subtitle)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.secondary)
                .padding(.top, 14)
            
            // Native Vertical Scrolling Wheel Picker with Numeric Range
            Picker("", selection: selection) {
                ForEach(Array(range), id: \.self) { num in
                    Text("\(num) \(unit)")
                        .font(.system(size: 22, weight: .medium, design: .rounded))
                        .tag(num)
                }
            }
            .pickerStyle(.wheel)
            .frame(height: 130)
            .clipped()
            .padding(.horizontal, 20)
            
            Button {
                onSave(selection.wrappedValue)
                activeSheet = nil
            } label: {
                Text("Confirm")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(
                        Capsule()
                            .fill(Color.blue)
                    )
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 24)
            .padding(.bottom, 12)
            
            Spacer()
        }
        .navigationTitle(title)
    }
    
    // MARK: - Weight Double Wheel Picker
    private var weightDoubleWheelPickerView: some View {
        VStack(spacing: 12) {
            Text("Select body weight (kg)")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.secondary)
                .padding(.top, 14)
            
            HStack(spacing: 0) {
                // Whole kg integer wheel
                Picker("", selection: $weightWholeKg) {
                    ForEach(20...200, id: \.self) { kg in
                        Text("\(kg)")
                            .font(.system(size: 23, weight: .semibold, design: .rounded))
                            .tag(kg)
                    }
                }
                .pickerStyle(.wheel)
                .frame(maxWidth: .infinity)
                
                // Decimal tenths wheel (0, 0.1, 0.2, ... 0.9)
                Picker("", selection: $weightDecimal) {
                    ForEach(0...9, id: \.self) { dec in
                        Text(dec == 0 ? "0" : "0.\(dec)")
                            .font(.system(size: 23, weight: .semibold, design: .rounded))
                            .tag(dec)
                    }
                }
                .pickerStyle(.wheel)
                .frame(maxWidth: .infinity)
            }
            .frame(height: 130)
            .clipped()
            .padding(.horizontal, 20)
            
            Button {
                viewModel.updateWeight("\(weightWholeKg).\(weightDecimal) kg")
                activeSheet = nil
            } label: {
                Text("Confirm")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(
                        Capsule()
                            .fill(Color.blue)
                    )
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 24)
            .padding(.bottom, 12)
            
            Spacer()
        }
        .navigationTitle("Weight")
    }
    
    // MARK: - Weekly Frequency Wheel Picker
    private var frequencyWheelPickerView: some View {
        VStack(spacing: 12) {
            Text("Select Weekly Frequency")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.secondary)
                .padding(.top, 14)
            
            // Native Vertical Scrolling Wheel Picker
            Picker("", selection: $selectedFrequency) {
                ForEach(ProfileOptions.frequencies, id: \.self) { item in
                    let label = item.contains("Everyday") ? item : (item.contains("week") ? item : "\(item)x week")
                    Text(label)
                        .font(.system(size: 21, weight: .medium, design: .rounded))
                        .tag(item)
                }
            }
            .pickerStyle(.wheel)
            .frame(height: 130)
            .clipped()
            .padding(.horizontal, 20)
            
            Button {
                let label = selectedFrequency.contains("Everyday") ? selectedFrequency : (selectedFrequency.contains("week") ? selectedFrequency : "\(selectedFrequency)x week")
                viewModel.updateWeeklyFrequency(label)
                activeSheet = nil
            } label: {
                Text("Confirm")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(
                        Capsule()
                            .fill(Color.blue)
                    )
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 24)
            .padding(.bottom, 12)
            
            Spacer()
        }
        .navigationTitle("Weekly Frequency")
    }
    
    // MARK: - Avatar Customizer (SwiftUI Icons & Color Palettes)
    private var avatarCustomizationView: some View {
        VStack(spacing: 18) {
            // Live Preview of Profile Icon
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                viewModel.profileAvatarColor.opacity(0.85),
                                viewModel.profileAvatarColor
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 74, height: 74)
                    .shadow(color: viewModel.profileAvatarColor.opacity(0.35), radius: 8, x: 0, y: 4)
                
                Image(systemName: viewModel.profileAvatarIcon)
                    .font(.system(size: 34, weight: .semibold))
                    .foregroundColor(.white)
            }
            .padding(.top, 6)
            
            // Icon Selector (Horizontal Scroll with Clean Margins)
            VStack(alignment: .leading, spacing: 8) {
                Text("CHOOSE SF SYMBOL ICON")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 20)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(ProfileOptions.avatarIcons, id: \.self) { icon in
                            let isSelected = (viewModel.profileAvatarIcon == icon)
                            Button {
                                viewModel.updateProfileAvatar(icon: icon, color: viewModel.profileAvatarColor)
                            } label: {
                                ZStack {
                                    Circle()
                                        .fill(isSelected ? viewModel.profileAvatarColor.opacity(0.18) : Color(uiColor: .systemGray6))
                                        .frame(width: 46, height: 46)
                                    
                                    Image(systemName: icon)
                                        .font(.system(size: 21, weight: isSelected ? .bold : .medium))
                                        .foregroundColor(isSelected ? viewModel.profileAvatarColor : .primary)
                                }
                                .overlay(
                                    Circle()
                                        .stroke(isSelected ? viewModel.profileAvatarColor : Color.clear, lineWidth: 2)
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 20)
                }
            }
            
            // Color Palette Selector
            VStack(alignment: .leading, spacing: 8) {
                Text("THEME COLOR")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 20)
                
                HStack(spacing: 16) {
                    ForEach(colorPalette, id: \.self) { color in
                        let isSelected = (viewModel.profileAvatarColor == color)
                        Button {
                            viewModel.updateProfileAvatar(icon: viewModel.profileAvatarIcon, color: color)
                        } label: {
                            Circle()
                                .fill(color)
                                .frame(width: 36, height: 36)
                                .overlay(
                                    Circle()
                                        .stroke(Color.white, lineWidth: isSelected ? 3 : 0)
                                )
                                .shadow(color: color.opacity(0.35), radius: 4, x: 0, y: 2)
                        }
                    }
                }
                .padding(.horizontal, 20)
            }
            
            Spacer()
        }
        .navigationTitle("Customize Profile Icon")
    }
    
    private let colorPalette: [Color] = [
        Color(red: 0.0, green: 0.48, blue: 1.0),   // Apple Blue
        Color(red: 0.35, green: 0.34, blue: 0.84), // Indigo
        Color(red: 0.69, green: 0.32, blue: 0.87), // Purple
        Color(red: 1.0, green: 0.18, blue: 0.33),  // Rose/Pink
        Color(red: 1.0, green: 0.58, blue: 0.0),   // Orange
        Color(red: 0.20, green: 0.78, blue: 0.35)  // Green
    ]
    
    // MARK: - Synchronizers & Number Parsers
    private func parseWeightNumber() {
        guard viewModel.weight != "-" else {
            weightWholeKg = 56
            weightDecimal = 0
            return
        }
        let clean = viewModel.weight
            .replacingOccurrences(of: "kg", with: "", options: .caseInsensitive)
            .trimmingCharacters(in: .whitespaces)
        
        let components = clean.components(separatedBy: ".")
        if components.count >= 2 {
            let wholeDigits = components[0].filter { "0123456789".contains($0) }
            let decDigits = components[1].filter { "0123456789".contains($0) }
            weightWholeKg = Int(wholeDigits) ?? 56
            weightDecimal = Int(decDigits.prefix(1)) ?? 0
        } else {
            let digits = clean.filter { "0123456789".contains($0) }
            weightWholeKg = Int(digits) ?? 56
            weightDecimal = 0
        }
    }
    
    private func parseHeightNumber() {
        guard viewModel.height != "-" else {
            selectedHeightCm = 165
            return
        }
        let digits = viewModel.height.filter { "0123456789".contains($0) }
        selectedHeightCm = Int(digits) ?? 165
    }
    
    private func syncCurrentFrequency() {
        let current = viewModel.weeklyFrequency
        guard current != "-" else {
            selectedFrequency = "3"
            return
        }
        if let match = ProfileOptions.frequencies.first(where: { current.contains($0) }) {
            selectedFrequency = match
        } else {
            selectedFrequency = ProfileOptions.frequencies.first ?? "3"
        }
    }
    
    private func saveCurrentSheetSelection() {
        guard let sheet = activeSheet else { return }
        switch sheet {
        case .avatar:
            break
        case .sportType:
            viewModel.updateSportType(selectedSportType)
        case .trainingLevel:
            viewModel.updateTrainingLevel(selectedTrainingLevel)
        case .weeklyFrequency:
            let label = selectedFrequency.contains("Everyday") ? selectedFrequency : (selectedFrequency.contains("week") ? selectedFrequency : "\(selectedFrequency)x week")
            viewModel.updateWeeklyFrequency(label)
        case .gender:
            viewModel.updateGender(selectedGender)
        case .weight:
            viewModel.updateWeight("\(weightWholeKg).\(weightDecimal) kg")
        case .height:
            viewModel.updateHeight("\(selectedHeightCm)cm")
        }
    }
}

// MARK: - Sheet Enum Helper
private enum ActiveProfileSheet: Identifiable {
    case avatar
    case sportType
    case trainingLevel
    case weeklyFrequency
    case gender
    case weight
    case height
    
    var id: String {
        switch self {
        case .avatar: return "avatar"
        case .sportType: return "sportType"
        case .trainingLevel: return "trainingLevel"
        case .weeklyFrequency: return "weeklyFrequency"
        case .gender: return "gender"
        case .weight: return "weight"
        case .height: return "height"
        }
    }
    
    var detents: Set<PresentationDetent> {
        switch self {
        case .avatar:
            return [.height(370)]
        case .sportType:
            return [.height(360)]
        case .trainingLevel, .weeklyFrequency, .gender, .height, .weight:
            return [.height(330)]
        }
    }
}

#Preview {
    ProfileView(viewModel: TrainingModel())
}
