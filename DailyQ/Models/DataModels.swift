//
//  DataModels.swift
//  DailyQ
//
//  Created by mac034 on 6/17/25.
//

import Foundation
import SwiftUI

// MARK: - TodoItem 모델
struct TodoItem: Identifiable, Codable {
    let id: UUID
    var text: String
    var isCompleted: Bool
    
    init(text: String, isCompleted: Bool = false) {
        self.id = UUID()
        self.text = text
        self.isCompleted = isCompleted
    }
}

// MARK: - AnswerData 모델 (AnswerView에서 사용)
struct AnswerData: Identifiable, Codable {
    let id: UUID
    let question: String
    let answer: String
    let date: Date
    
    init(question: String, answer: String, date: Date) {
        self.id = UUID()
        self.question = question
        self.answer = answer
        self.date = date
    }
}

// MARK: - StatsData 모델 (StatsView에서 사용)
struct StatsData {
    let totalAnswers: Int
    let thisMonthAnswers: Int
    let thisWeekAnswers: Int
    let currentStreak: Int
    let maxStreak: Int
    let monthlyStats: [(month: String, count: Int)]
}

// MARK: - DataManager
class DataManager: ObservableObject {
    static let shared = DataManager()
    
    private init() {}
    
    // 날짜를 일관된 형식으로 변환하는 helper 함수
    private func dateKey(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = TimeZone(identifier: "Asia/Seoul") ?? TimeZone.current
        return formatter.string(from: date)
    }
    
    // 날짜의 시작 시간으로 정규화하는 함수
    private func normalizeDate(_ date: Date) -> Date {
        let calendar = Calendar.current
        return calendar.startOfDay(for: date)
    }
    
    // MARK: - Question 관련 메서드들
    func saveQuestion(_ question: String, for date: Date) {
        let key = dateKey(for: date)
        UserDefaults.standard.set(question, forKey: "question_\(key)")
        
        // 마지막 질문 생성 날짜도 동일한 형식으로 저장
        UserDefaults.standard.set(key, forKey: "lastQuestionDate")
    }
    
    func getQuestion(for date: Date) -> String? {
        let key = dateKey(for: date)
        return UserDefaults.standard.string(forKey: "question_\(key)")
    }
    
    // MARK: - Answer 관련 메서드들
    func saveAnswer(_ answer: String, for date: Date) {
        let key = dateKey(for: date)
        UserDefaults.standard.set(answer, forKey: "answer_\(key)")
        
        // 답변과 함께 질문도 AnswerData로 저장
        if let question = getQuestion(for: date) {
            saveAnswerData(question: question, answer: answer, date: date)
        }
    }
    
    func getAnswer(for date: Date) -> String? {
        let key = dateKey(for: date)
        return UserDefaults.standard.string(forKey: "answer_\(key)")
    }
    
    // MARK: - AnswerData 관련 메서드들 (AnswerView용)
    private func saveAnswerData(question: String, answer: String, date: Date) {
        var savedAnswers = getAllAnswers()
        
        // 같은 날짜의 답변이 있다면 업데이트, 없다면 추가
        let normalizedDate = normalizeDate(date)
        if let index = savedAnswers.firstIndex(where: { normalizeDate($0.date) == normalizedDate }) {
            savedAnswers[index] = AnswerData(question: question, answer: answer, date: normalizedDate)
        } else {
            savedAnswers.append(AnswerData(question: question, answer: answer, date: normalizedDate))
        }
        
        // 날짜순으로 정렬 (최신순)
        savedAnswers.sort { $0.date > $1.date }
        
        if let encoded = try? JSONEncoder().encode(savedAnswers) {
            UserDefaults.standard.set(encoded, forKey: "allAnswers")
        }
    }
    
    func getAllAnswers() -> [AnswerData] {
        guard let data = UserDefaults.standard.data(forKey: "allAnswers"),
              let answers = try? JSONDecoder().decode([AnswerData].self, from: data) else {
            return []
        }
        return answers
    }
    
    // MARK: - TodoList 관련 메서드들
    func saveTodoList(_ todos: [TodoItem], for date: Date) {
        let key = dateKey(for: date)
        if let encoded = try? JSONEncoder().encode(todos) {
            UserDefaults.standard.set(encoded, forKey: "todos_\(key)")
        }
    }
    
    func getTodoList(for date: Date) -> [TodoItem] {
        let key = dateKey(for: date)
        guard let data = UserDefaults.standard.data(forKey: "todos_\(key)"),
              let todos = try? JSONDecoder().decode([TodoItem].self, from: data) else {
            return []
        }
        return todos
    }
    
    func getLastQuestionDate() -> String? {
        return UserDefaults.standard.string(forKey: "lastQuestionDate")
    }
    
    // MARK: - Stats 관련 메서드들 (StatsView용)
    func getStatsData() -> StatsData {
        let allAnswers = getAllAnswers()
        let calendar = Calendar.current
        let now = Date()
        
        // 전체 답변 수
        let totalAnswers = allAnswers.count
        
        // 이번 달 답변 수
        let startOfMonth = calendar.dateInterval(of: .month, for: now)?.start ?? now
        let thisMonthAnswers = allAnswers.filter { $0.date >= startOfMonth }.count
        
        // 이번 주 답변 수
        let oneWeekAgo = calendar.date(byAdding: .day, value: -7, to: now) ?? now
        let thisWeekAnswers = allAnswers.filter { $0.date >= oneWeekAgo }.count
        
        // 연속 작성 기록 계산
        let (currentStreak, maxStreak) = calculateStreaks(from: allAnswers)
        
        // 월별 통계 (최근 3개월)
        let monthlyStats = calculateMonthlyStats(from: allAnswers, calendar: calendar)
        
        return StatsData(
            totalAnswers: totalAnswers,
            thisMonthAnswers: thisMonthAnswers,
            thisWeekAnswers: thisWeekAnswers,
            currentStreak: currentStreak,
            maxStreak: maxStreak,
            monthlyStats: monthlyStats
        )
    }
    
    private func calculateStreaks(from answers: [AnswerData]) -> (current: Int, max: Int) {
        guard !answers.isEmpty else { return (0, 0) }
        
        let calendar = Calendar.current
        let today = normalizeDate(Date())
        
        // 날짜별로 정렬 (오래된 순)
        let sortedAnswers = answers.sorted { $0.date < $1.date }
        let uniqueDates = Array(Set(sortedAnswers.map { normalizeDate($0.date) })).sorted()
        
        var currentStreak = 0
        var maxStreak = 0
        var tempStreak = 0
        
        // 현재 연속 기록 계산
        var checkDate = today
        for _ in 0..<365 { // 최대 1년까지 확인
            if uniqueDates.contains(checkDate) {
                currentStreak += 1
                checkDate = calendar.date(byAdding: .day, value: -1, to: checkDate) ?? checkDate
            } else {
                break
            }
        }
        
        // 최대 연속 기록 계산
        for i in 0..<uniqueDates.count {
            tempStreak = 1
            
            for j in (i + 1)..<uniqueDates.count {
                let prevDate = uniqueDates[j - 1]
                let currentDate = uniqueDates[j]
                
                if calendar.dateComponents([.day], from: prevDate, to: currentDate).day == 1 {
                    tempStreak += 1
                } else {
                    break
                }
            }
            
            maxStreak = max(maxStreak, tempStreak)
        }
        
        return (currentStreak, maxStreak)
    }
    
    private func calculateMonthlyStats(from answers: [AnswerData], calendar: Calendar) -> [(month: String, count: Int)] {
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "ko_KR")
        dateFormatter.dateFormat = "M월"
        
        var monthlyCount: [String: Int] = [:]
        
        // 최근 3개월의 데이터만 계산
        let now = Date()
        for i in 0..<3 {
            guard let monthDate = calendar.date(byAdding: .month, value: -i, to: now) else { continue }
            let monthString = dateFormatter.string(from: monthDate)
            monthlyCount[monthString] = 0
        }
        
        // 답변 개수 계산
        for answer in answers {
            let monthString = dateFormatter.string(from: answer.date)
            if monthlyCount.keys.contains(monthString) {
                monthlyCount[monthString, default: 0] += 1
            }
        }
        
        // 월별로 정렬해서 반환 (최근 달부터)
        return monthlyCount.sorted { first, second in
            // 월 번호로 비교하여 정렬
            let firstMonth = Int(first.key.replacingOccurrences(of: "월", with: "")) ?? 0
            let secondMonth = Int(second.key.replacingOccurrences(of: "월", with: "")) ?? 0
            return firstMonth > secondMonth
        }.map { (month: $0.key, count: $0.value) }
    }
    
    // MARK: - Settings 관련 메서드들
    func getPushNotificationEnabled() -> Bool {
        return UserDefaults.standard.bool(forKey: "pushNotificationEnabled")
    }
    
    func setPushNotificationEnabled(_ enabled: Bool) {
        UserDefaults.standard.set(enabled, forKey: "pushNotificationEnabled")
    }
    
    func getDarkModeEnabled() -> Bool {
        return UserDefaults.standard.bool(forKey: "darkModeEnabled")
    }
    
    func setDarkModeEnabled(_ enabled: Bool) {
        UserDefaults.standard.set(enabled, forKey: "darkModeEnabled")
    }
    
    func getNotificationTime() -> (hour: Int, minute: Int) {
        let hour = UserDefaults.standard.integer(forKey: "notificationHour")
        let minute = UserDefaults.standard.integer(forKey: "notificationMinute")
        return (hour == 0 && minute == 0) ? (20, 0) : (hour, minute) // 기본값 오후 8시
    }
    
    func setNotificationTime(hour: Int, minute: Int) {
        UserDefaults.standard.set(hour, forKey: "notificationHour")
        UserDefaults.standard.set(minute, forKey: "notificationMinute")
    }
    
    // MARK: - 데이터 삭제
    func clearAllData() {
        let domain = Bundle.main.bundleIdentifier!
        UserDefaults.standard.removePersistentDomain(forName: domain)
        UserDefaults.standard.synchronize()
    }
}
