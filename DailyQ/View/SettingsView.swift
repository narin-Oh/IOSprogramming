//
//  SettingsView.swift
//  DailyQ
//
//  Created by mac034 on 6/17/25.
//
import SwiftUI

struct SettingsView: View {
    @StateObject private var dataManager = DataManager.shared
    @StateObject private var notificationManager = NotificationManager.shared
    @Environment(\.dismiss) private var dismiss
    
    @State private var pushNotificationEnabled = false
    @State private var darkModeEnabled = false
    @State private var notificationHour = 20
    @State private var notificationMinute = 0
    @State private var showingTimePicker = false
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    // 개발자 옵션 관련
    @State private var developerTapCount = 0
    @State private var showingDeveloperOptions = false
    
    var body: some View {
        ZStack {
            Color.backgroundColor
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // 상단 네비게이션 바
                HStack {
                    Button(action: { dismiss() }) {
                        HStack(spacing: 6) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 16, weight: .semibold))
                            Text("Back")
                                .font(.system(size: 16, weight: .medium))
                        }
                        .foregroundColor(.blue)
                    }
                    
                    Spacer()
                    
                    Text("설정")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(Color.letterColor)
                    
                    Spacer()
                    
                    // 균형을 위한 빈 공간
                    HStack(spacing: 6) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .semibold))
                        Text("Back")
                            .font(.system(size: 16, weight: .medium))
                    }
                    .opacity(0)
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 16)
                
                // 헤더
                SettingsHeaderView()
                
                ScrollView {
                    VStack(spacing: 16) {
                        // 알림 설정
                        NotificationSettingsCard(
                            pushEnabled: $pushNotificationEnabled,
                            hour: notificationHour,
                            minute: notificationMinute,
                            onNotificationToggle: togglePushNotification,
                            onTimeChange: { showingTimePicker = true }
                        )
                        
                        // 테마 설정
                        ThemeSettingsCard(
                            darkModeEnabled: $darkModeEnabled,
                            onDarkModeToggle: toggleDarkMode
                        )
                        
                        // 앱 정보
                        AppInfoCard(onVersionTap: handleVersionTap)
                        
                        // 개발자 옵션 (숨겨진)
                        if showingDeveloperOptions {
                            DeveloperOptionsCard(
                                dataManager: dataManager,
                                notificationManager: notificationManager
                            )
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 40)
                }
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            loadSettings()
        }
        .sheet(isPresented: $showingTimePicker) {
            TimePickerModal(
                hour: $notificationHour,
                minute: $notificationMinute,
                onSave: updateNotificationTime
            )
        }
        .alert("알림", isPresented: $showingAlert) {
            Button("확인", role: .cancel) { }
        } message: {
            Text(alertMessage)
        }
    }
    
    // MARK: - 설정 로드
    private func loadSettings() {
        pushNotificationEnabled = dataManager.getPushNotificationEnabled()
        darkModeEnabled = dataManager.getDarkModeEnabled()
        let time = dataManager.getNotificationTime()
        notificationHour = time.hour
        notificationMinute = time.minute
    }
    
    // MARK: - 푸시 알림 토글
    private func togglePushNotification() {
        if !pushNotificationEnabled && !notificationManager.hasPermission {
            notificationManager.requestPermission()
            return
        }
        
        pushNotificationEnabled.toggle()
        dataManager.setPushNotificationEnabled(pushNotificationEnabled)
        
        if pushNotificationEnabled {
            notificationManager.scheduleDailyNotification(hour: notificationHour, minute: notificationMinute)
            alertMessage = "푸시 알림이 활성화되었습니다"
        } else {
            notificationManager.cancelDailyNotification()
            alertMessage = "푸시 알림이 비활성화되었습니다"
        }
        showingAlert = true
    }
    
    // MARK: - 다크 모드 토글
    private func toggleDarkMode() {
        darkModeEnabled.toggle()
        dataManager.setDarkModeEnabled(darkModeEnabled)
        alertMessage = "테마가 변경되었습니다"
        showingAlert = true
    }
    
    // MARK: - 알림 시간 업데이트
    private func updateNotificationTime() {
        dataManager.setNotificationTime(hour: notificationHour, minute: notificationMinute)
        
        if pushNotificationEnabled {
            notificationManager.scheduleDailyNotification(hour: notificationHour, minute: notificationMinute)
        }
        
        alertMessage = "알림 시간이 변경되었습니다"
        showingAlert = true
    }
    
    // MARK: - 개발자 옵션 (버전 탭)
    private func handleVersionTap() {
        developerTapCount += 1
        
        if developerTapCount >= 5 {
            showingDeveloperOptions = true
            developerTapCount = 0
            alertMessage = "개발자 옵션이 활성화되었습니다"
            showingAlert = true
        }
        
        // 3초 후 탭 카운트 리셋
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            if developerTapCount > 0 {
                developerTapCount = 0
            }
        }
    }
}

// MARK: - 헤더 뷰
struct SettingsHeaderView: View {
    var body: some View {
        VStack(spacing: 4) {
            Text("설정")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(Color.letterColor)
            
            Text("앱 환경설정")
                .font(.subheadline)
                .foregroundColor(Color.letterColor)
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .background(Color.mainColor)
        .cornerRadius(12)
        .padding(.horizontal, 16)
        .padding(.bottom, 20)
    }
}

// MARK: - 알림 설정 카드
struct NotificationSettingsCard: View {
    @Binding var pushEnabled: Bool
    let hour: Int
    let minute: Int
    let onNotificationToggle: () -> Void
    let onTimeChange: () -> Void
    
    private var timeString: String {
        let amPm = hour < 12 ? "오전" : "오후"
        let displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour)
        return "매일 \(amPm) \(displayHour)시 \(String(format: "%02d", minute))분"
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("알림 설정")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(Color.letterColor)
            
            // 푸시 알림
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("푸시 알림")
                        .font(.body)
                        .foregroundColor(Color.letterColor)
                    
                    Text("새로운 질문 알림을 받습니다")
                        .font(.caption)
                        .foregroundColor(Color.grayColor)
                }
                
                Spacer()
                
                Toggle("", isOn: $pushEnabled)
                    .onChange(of: pushEnabled) { _ in
                        onNotificationToggle()
                    }
            }
            
            // 알림 시간
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("알림 시간")
                        .font(.body)
                        .foregroundColor(Color.letterColor)
                    
                    Text(timeString)
                        .font(.caption)
                        .foregroundColor(Color.grayColor)
                }
                
                Spacer()
                
                Button("변경") {
                    onTimeChange()
                }
                .font(.subheadline)
                .foregroundColor(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.mainColor)
                .cornerRadius(6)
            }
        }
        .padding(16)
        .background(Color.lightGrayColor)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
}

// MARK: - 테마 설정 카드
struct ThemeSettingsCard: View {
    @Binding var darkModeEnabled: Bool
    let onDarkModeToggle: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("테마 설정")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(Color.letterColor)
            
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("다크 모드")
                        .font(.body)
                        .foregroundColor(Color.letterColor)
                    
                    Text("어두운 테마를 사용합니다")
                        .font(.caption)
                        .foregroundColor(Color.grayColor)
                }
                
                Spacer()
                
                Toggle("", isOn: $darkModeEnabled)
                    .onChange(of: darkModeEnabled) { _ in
                        onDarkModeToggle()
                    }
            }
        }
        .padding(16)
        .background(Color.lightGrayColor)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
}

// MARK: - 앱 정보 카드
struct AppInfoCard: View {
    let onVersionTap: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("앱 정보")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(Color.letterColor)
            
            // 버전 정보
            HStack {
                Text("버전")
                    .font(.body)
                    .foregroundColor(Color.letterColor)
                
                Spacer()
                
                Button("1.0.0") {
                    onVersionTap()
                }
                .font(.body)
                .foregroundColor(Color.grayColor)
            }
            
            // 개발자 정보
            HStack {
                Text("개발자")
                    .font(.body)
                    .foregroundColor(Color.letterColor)
                
                Spacer()
                
                Text("오나린")
                    .font(.body)
                    .foregroundColor(Color.grayColor)
            }
        }
        .padding(16)
        .background(Color.lightGrayColor)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
}

// MARK: - 개발자 옵션 카드
struct DeveloperOptionsCard: View {
    let dataManager: DataManager
    let notificationManager: NotificationManager
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("🛠️ 개발자 옵션")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(Color.red)
            
            VStack(spacing: 12) {
                DeveloperButton(title: "테스트 알림 보내기") {
                    notificationManager.sendTestNotification()
                    alertMessage = "테스트 알림이 전송되었습니다"
                    showingAlert = true
                }
                
                DeveloperButton(title: "모든 데이터 삭제", isDestructive: true) {
                    dataManager.clearAllData()
                    alertMessage = "모든 데이터가 삭제되었습니다"
                    showingAlert = true
                }
            }
        }
        .padding(16)
        .background(Color.red.opacity(0.1))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.red.opacity(0.3), lineWidth: 1)
        )
        .alert("개발자 옵션", isPresented: $showingAlert) {
            Button("확인", role: .cancel) { }
        } message: {
            Text(alertMessage)
        }
    }
}

struct DeveloperButton: View {
    let title: String
    let isDestructive: Bool
    let action: () -> Void
    
    init(title: String, isDestructive: Bool = false, action: @escaping () -> Void) {
        self.title = title
        self.isDestructive = isDestructive
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(isDestructive ? Color.red : Color.blue)
                .cornerRadius(6)
        }
    }
}

// MARK: - 시간 선택 모달
struct TimePickerModal: View {
    @Binding var hour: Int
    @Binding var minute: Int
    let onSave: () -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                Text("알림 시간 설정")
                    .font(.title2)
                    .fontWeight(.bold)
                
                HStack(spacing: 20) {
                    // 시간 선택
                    VStack {
                        Text("시")
                            .font(.headline)
                        
                        Picker("시간", selection: $hour) {
                            ForEach(0..<24, id: \.self) { hour in
                                Text("\(hour)시").tag(hour)
                            }
                        }
                        .pickerStyle(WheelPickerStyle())
                        .frame(width: 100, height: 150)
                    }
                    
                    // 분 선택
                    VStack {
                        Text("분")
                            .font(.headline)
                        
                        Picker("분", selection: $minute) {
                            ForEach(0..<60, id: \.self) { minute in
                                Text("\(minute)분").tag(minute)
                            }
                        }
                        .pickerStyle(WheelPickerStyle())
                        .frame(width: 100, height: 150)
                    }
                }
                
                Spacer()
            }
            .padding(20)
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("취소") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("저장") {
                        onSave()
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
}

// MARK: - 미리보기
struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            SettingsView()
        }
    }
}
