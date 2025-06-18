//
//  CalendarView.swift
//  DailyQ
//
//  Created by mac034 on 6/17/25.
//
import SwiftUI

struct CalendarView: View {
    // DataManager 싱글톤 인스턴스 직접 참조
    private let dataManager = DataManager.shared
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedDate = Date()
    @State private var currentMonth = Date()
    @State private var selectedQuestion: String?
    @State private var selectedAnswer: String?
    @State private var selectedTodos: [TodoItem] = []
    
    private let calendar = Calendar.current
    
    var body: some View {
        ZStack {
            Color("BackgroundColor")
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // 상단 네비게이션 바 (고정)
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
                    
                    Text("기록 보기")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(Color("LetterColor"))
                    
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
                .background(Color("BackgroundColor"))
                
                // 스크롤 가능한 콘텐츠
                ScrollView {
                    VStack(spacing: 0) {
                        // 헤더
                        CalendarHeaderView(selectedDate: selectedDate)
                        
                        // 캘린더 카드
                        CalendarCardView(
                            currentMonth: $currentMonth,
                            selectedDate: $selectedDate,
                            onDateSelected: onDateSelected
                        )
                        
                        // 선택된 날짜 데이터
                        SelectedDateDataView(
                            date: selectedDate,
                            question: selectedQuestion,
                            answer: selectedAnswer,
                            todos: selectedTodos
                        )
                        
                        // 하단 여백
                        Spacer()
                            .frame(height: 40)
                    }
                }
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            onDateSelected(selectedDate)
        }
    }
    
    private func onDateSelected(_ date: Date) {
        // 날짜를 하루의 시작 시간으로 정규화
        let normalizedDate = calendar.startOfDay(for: date)
        selectedDate = normalizedDate
        loadDataForSelectedDate()
    }
    
    private func loadDataForSelectedDate() {
        // 날짜를 정규화하여 데이터 로드
        let normalizedDate = calendar.startOfDay(for: selectedDate)
        
        selectedQuestion = dataManager.getQuestion(for: normalizedDate)
        selectedAnswer = dataManager.getAnswer(for: normalizedDate)
        selectedTodos = dataManager.getTodoList(for: normalizedDate)
        
        // 디버깅용 로그
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        print("Loading data for: \(formatter.string(from: normalizedDate))")
        print("Question: \(selectedQuestion ?? "nil")")
        print("Answer: \(selectedAnswer ?? "nil")")
        print("Todos count: \(selectedTodos.count)")
    }
}

// MARK: - 캘린더 헤더
struct CalendarHeaderView: View {
    let selectedDate: Date
    
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy년 M월 d일"
        formatter.locale = Locale(identifier: "ko_KR")
        return formatter.string(from: selectedDate)
    }
    
    var body: some View {
        VStack(spacing: 8) {
            Text("선택된 날짜")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(Color("LetterColor"))
            
            Text(formattedDate)
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(Color("LetterColor"))
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .background(Color("MainColor"))
        .cornerRadius(12)
        .padding(.horizontal, 16)
        .padding(.bottom, 16)
    }
}

// MARK: - 캘린더 카드
struct CalendarCardView: View {
    @Binding var currentMonth: Date
    @Binding var selectedDate: Date
    let onDateSelected: (Date) -> Void
    
    private let calendar = Calendar.current
    
    var body: some View {
        VStack(spacing: 16) {
            // 캘린더 헤더
            CalendarControlHeader(currentMonth: $currentMonth)
            
            // 요일 헤더
            WeekdayHeader()
            
            // 캘린더 그리드
            CalendarGrid(
                currentMonth: currentMonth,
                selectedDate: $selectedDate,
                onDateSelected: onDateSelected
            )
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 6, x: 0, y: 2)
        .padding(.horizontal, 16)
        .padding(.bottom, 16)
    }
}

// MARK: - 캘린더 컨트롤 헤더
struct CalendarControlHeader: View {
    @Binding var currentMonth: Date
    private let calendar = Calendar.current
    
    private var monthYearString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy년 M월"
        formatter.locale = Locale(identifier: "ko_KR")
        return formatter.string(from: currentMonth)
    }
    
    var body: some View {
        HStack {
            Button(action: previousMonth) {
                Image(systemName: "chevron.left")
                    .font(.title2)
                    .foregroundColor(Color("MainColor"))
            }
            
            Spacer()
            
            Text(monthYearString)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(Color("LetterColor"))
            
            Spacer()
            
            Button(action: nextMonth) {
                Image(systemName: "chevron.right")
                    .font(.title2)
                    .foregroundColor(Color("MainColor"))
            }
        }
    }
    
    private func previousMonth() {
        withAnimation(.easeInOut(duration: 0.3)) {
            currentMonth = calendar.date(byAdding: .month, value: -1, to: currentMonth) ?? currentMonth
        }
    }
    
    private func nextMonth() {
        withAnimation(.easeInOut(duration: 0.3)) {
            currentMonth = calendar.date(byAdding: .month, value: 1, to: currentMonth) ?? currentMonth
        }
    }
}

// MARK: - 요일 헤더
struct WeekdayHeader: View {
    private let weekdays = ["일", "월", "화", "수", "목", "금", "토"]
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(weekdays, id: \.self) { weekday in
                Text(weekday)
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(weekday == "일" ? Color.red : (weekday == "토" ? Color.blue : Color("LetterColor")))
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(.vertical, 8)
        .background(Color("LightGrayColor"))
        .cornerRadius(8)
    }
}

// MARK: - 캘린더 그리드
struct CalendarGrid: View {
    // DataManager 싱글톤 인스턴스 직접 참조
    private let dataManager = DataManager.shared
    let currentMonth: Date
    @Binding var selectedDate: Date
    let onDateSelected: (Date) -> Void
    
    private let calendar = Calendar.current
    
    private var monthDates: [Date] {
        guard let monthRange = calendar.range(of: .day, in: .month, for: currentMonth),
              let firstOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: currentMonth)) else {
            return []
        }
        
        let firstWeekday = calendar.component(.weekday, from: firstOfMonth)
        let offsetDays = firstWeekday - 1
        
        var dates: [Date] = []
        
        // 이전 달의 날짜들
        for i in 0..<offsetDays {
            if let date = calendar.date(byAdding: .day, value: -offsetDays + i, to: firstOfMonth) {
                dates.append(date)
            }
        }
        
        // 현재 달의 날짜들
        for day in monthRange {
            if let date = calendar.date(byAdding: .day, value: day - 1, to: firstOfMonth) {
                dates.append(date)
            }
        }
        
        // 다음 달의 날짜들 (6주 완성을 위해)
        let remainingDays = 42 - dates.count
        for i in 0..<remainingDays {
            if let lastDate = dates.last,
               let date = calendar.date(byAdding: .day, value: i + 1, to: lastDate) {
                dates.append(date)
            }
        }
        
        return dates
    }
    
    var body: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 8) {
            ForEach(monthDates, id: \.self) { date in
                CalendarDayView(
                    date: date,
                    currentMonth: currentMonth,
                    selectedDate: selectedDate,
                    hasData: hasDataForDate(date),
                    onTap: { onDateSelected(date) }
                )
            }
        }
    }
    
    private func hasDataForDate(_ date: Date) -> Bool {
        // 날짜를 정규화하여 비교
        let normalizedDate = calendar.startOfDay(for: date)
        
        let hasQuestion = dataManager.getQuestion(for: normalizedDate) != nil
        let hasAnswer = dataManager.getAnswer(for: normalizedDate) != nil
        let hasTodos = !dataManager.getTodoList(for: normalizedDate).isEmpty
        
        return hasQuestion || hasAnswer || hasTodos
    }
}

// MARK: - 캘린더 날짜 뷰
struct CalendarDayView: View {
    let date: Date
    let currentMonth: Date
    let selectedDate: Date
    let hasData: Bool
    let onTap: () -> Void
    
    private let calendar = Calendar.current
    
    private var dayNumber: String {
        return "\(calendar.component(.day, from: date))"
    }
    
    private var isInCurrentMonth: Bool {
        calendar.isDate(date, equalTo: currentMonth, toGranularity: .month)
    }
    
    private var isToday: Bool {
        calendar.isDateInToday(date)
    }
    
    private var isSelected: Bool {
        let normalizedDate = calendar.startOfDay(for: date)
        let normalizedSelectedDate = calendar.startOfDay(for: selectedDate)
        return calendar.isDate(normalizedDate, inSameDayAs: normalizedSelectedDate)
    }
    
    var body: some View {
        Button(action: onTap) {
            ZStack {
                // 배경
                Circle()
                    .fill(isSelected ? Color("MainColor") : Color.clear)
                    .frame(width: 40, height: 40)
                
                // 오늘 표시
                if isToday && !isSelected {
                    Circle()
                        .stroke(Color("MainColor"), lineWidth: 2)
                        .frame(width: 40, height: 40)
                }
                
                // 날짜 텍스트
                Text(dayNumber)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(textColor)
                
                // 데이터 인디케이터
                if hasData && isInCurrentMonth {
                    Circle()
                        .fill(Color.red)
                        .frame(width: 6, height: 6)
                        .offset(x: 12, y: -12)
                }
            }
        }
        .frame(width: 44, height: 44)
    }
    
    private var textColor: Color {
        if isSelected {
            return .white
        } else if isToday {
            return Color("MainColor")
        } else if isInCurrentMonth {
            return Color("LetterColor")
        } else {
            return Color("BlueGrayColor").opacity(0.4)
        }
    }
}

// MARK: - 선택된 날짜 데이터 뷰
struct SelectedDateDataView: View {
    let date: Date
    let question: String?
    let answer: String?
    let todos: [TodoItem]
    
    private var hasAnyData: Bool {
        question != nil || answer != nil || !todos.isEmpty
    }
    
    var body: some View {
        VStack(spacing: 16) {
            // 섹션 헤더
            HStack {
                Image(systemName: "doc.text.fill")
                    .foregroundColor(Color("MainColor"))
                
                Text("선택된 날짜 기록")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(Color("LetterColor"))
                
                Spacer()
            }
            
            Rectangle()
                .fill(Color("MainColor"))
                .frame(height: 2)
            
            if hasAnyData {
                VStack(spacing: 16) {
                    // 질문 섹션
                    if let question = question {
                        QuestionAnswerSection(question: question, answer: answer)
                    }
                    
                    // 할 일 섹션
                    if !todos.isEmpty {
                        TodoSection(todos: todos)
                    }
                }
            } else {
                NoDataView()
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 6, x: 0, y: 2)
        .padding(.horizontal, 16)
    }
}

// MARK: - 질문 답변 섹션
struct QuestionAnswerSection: View {
    let question: String
    let answer: String?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 질문
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("오늘의 질문")
                        .font(.headline)
                        .foregroundColor(Color("MainColor"))
                }
                
                Text(question)
                    .font(.body)
                    .foregroundColor(Color("LetterColor"))
                    .padding()
                    .background(Color("LightGrayColor"))
                    .cornerRadius(8)
            }
            
            // 답변
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("나의 답변")
                        .font(.headline)
                        .foregroundColor(Color("MainColor"))
                }
                
                if let answer = answer, !answer.isEmpty {
                    Text(answer)
                        .font(.body)
                        .foregroundColor(Color("LetterColor"))
                        .padding()
                        .background(Color("LightGrayColor"))
                        .cornerRadius(8)
                } else {
                    Text("아직 답변이 작성되지 않았습니다.")
                        .font(.body)
                        .foregroundColor(Color("letterColor"))
                        .padding()
                        .background(Color("LightGrayColor"))
                        .cornerRadius(8)
                }
            }
        }
    }
}

// MARK: - 할 일 섹션
struct TodoSection: View {
    let todos: [TodoItem]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("✅")
                Text("할 일 목록")
                    .font(.headline)
                    .foregroundColor(Color("MainColor"))
            }
            
            VStack(spacing: 8) {
                ForEach(todos, id: \.id) { todo in
                    HStack {
                        Text(todo.isCompleted ? "✅" : "⭕")
                        Text(todo.text)
                            .font(.body)
                            .foregroundColor(todo.isCompleted ? Color("LetterColor") : Color("LetterColor"))
                            .strikethrough(todo.isCompleted)
                        Spacer()
                    }
                    .padding(.vertical, 4)
                    .padding(.horizontal, 8)
                    .background(Color("LightGrayColor"))
                    .cornerRadius(6)
                }
            }
        }
    }
}

// MARK: - 데이터 없음 뷰
struct NoDataView: View {
    var body: some View {
        VStack(spacing: 16) {
            Text("📋")
                .font(.system(size: 48))
            
            Text("선택한 날짜에 등록된 데이터가 없습니다.")
                .font(.body)
                .foregroundColor(Color("LetterColor"))
                .multilineTextAlignment(.center)
            
            Text("질문이나 할 일을 추가해보세요!")
                .font(.subheadline)
                .foregroundColor(Color("LetterColor"))
        }
        .padding(.vertical, 32)
    }
}

// MARK: - 미리보기
struct CalendarView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            CalendarView()
        }
    }
}
