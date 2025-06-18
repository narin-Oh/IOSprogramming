//
//  NotificationManager.swift
//  DailyQ
//
//  Created by mac034 on 6/18/25.
//

import Foundation
import UserNotifications

class NotificationManager: ObservableObject {
    static let shared = NotificationManager()
    
    @Published var hasPermission = false
    
    private init() {
        checkPermission()
    }
    
    // MARK: - 권한 확인
    func checkPermission() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                self.hasPermission = settings.authorizationStatus == .authorized
            }
        }
    }
    
    // MARK: - 권한 요청
    func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            DispatchQueue.main.async {
                self.hasPermission = granted
                if granted {
                    print("알림 권한이 허용되었습니다.")
                } else if let error = error {
                    print("알림 권한 요청 실패: \(error)")
                }
            }
        }
    }
    
    // MARK: - 매일 알림 예약
    func scheduleDailyNotification(hour: Int, minute: Int) {
        // 기존 알림 취소
        cancelDailyNotification()
        
        // 알림 콘텐츠 생성
        let content = UNMutableNotificationContent()
        content.title = "Daily Q"
        content.body = "오늘의 새로운 질문이 도착했습니다!"
        content.sound = .default
        content.badge = 1
        
        // 트리거 생성 (매일 특정 시간)
        var dateComponents = DateComponents()
        dateComponents.hour = hour
        dateComponents.minute = minute
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        
        // 요청 생성
        let request = UNNotificationRequest(
            identifier: "dailyQuestion",
            content: content,
            trigger: trigger
        )
        
        // 알림 등록
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("알림 등록 실패: \(error)")
            } else {
                print("알림이 등록되었습니다: 매일 \(hour)시 \(minute)분")
            }
        }
    }
    
    // MARK: - 알림 취소
    func cancelDailyNotification() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["dailyQuestion"])
    }
    
    // MARK: - 테스트 알림
    func sendTestNotification() {
        let content = UNMutableNotificationContent()
        content.title = "테스트 알림"
        content.body = "이것은 테스트 알림입니다."
        content.sound = .default
        
        // 5초 후 트리거
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)
        
        let request = UNNotificationRequest(
            identifier: "testNotification",
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("테스트 알림 등록 실패: \(error)")
            } else {
                print("테스트 알림이 5초 후에 표시됩니다.")
            }
        }
    }
    
    // MARK: - 배지 제거
    func clearBadge() {
        UNUserNotificationCenter.current().setBadgeCount(0) { error in
            if let error = error {
                print("배지 제거 실패: \(error)")
            }
        }
    }
}
