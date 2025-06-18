//
//  DailyQView.swift
//  DailyQ
//
//  Created by mac034 on 6/17/25.
//
import SwiftUI
import Combine

struct DailyQView: View {
    // @EnvironmentObject 대신 @StateObject 또는 직접 인스턴스 사용
    @StateObject private var dataManager = DataManager.shared
    @StateObject private var networkManager = NetworkManager.shared
    @Environment(\.dismiss) private var dismiss
    @State private var apiState: APIState = .idle
    @State private var currentQuestion = ""
    @State private var currentAnswer = ""
    @State private var hasQuestionForToday = false
    @State private var hasAnsweredToday = false
    @State private var showingAlert = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    @State private var cancellables = Set<AnyCancellable>()
    
    private let today = Date()
    
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
                    
                    Text("오늘의 질문")
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
                
                VStack(spacing: 0) {
                    // 커스텀 헤더
                    DailyQHeaderView()
                    
                    // 상태 메시지
                    if let statusMessage = getStatusMessage() {
                        StatusMessageView(message: statusMessage, messageType: getMessageType())
                    }
                    
                    // 질문 영역
                    QuestionSectionView(question: currentQuestion, state: apiState)
                    
                    // 답변 입력 영역
                    AnswerInputSection(
                        answer: $currentAnswer,
                        isEnabled: hasQuestionForToday,
                        onSave: saveAnswer
                    )
                    
                    Spacer()
                }
                .padding(.horizontal, 16)
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            checkTodayStatus()
        }
        .alert(alertTitle, isPresented: $showingAlert) {
            Button("확인", role: .cancel) { }
        } message: {
            Text(alertMessage)
        }
    }
    
    // MARK: - 오늘 상태 확인
    private func checkTodayStatus() {
        // 오늘 날짜를 정규화
        let normalizedToday = Calendar.current.startOfDay(for: today)
        
        let savedQuestion = dataManager.getQuestion(for: normalizedToday)
        let savedAnswer = dataManager.getAnswer(for: normalizedToday)
        let lastQuestionDate = dataManager.getLastQuestionDate()
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let todayString = formatter.string(from: normalizedToday)
        
        hasQuestionForToday = savedQuestion != nil
        hasAnsweredToday = savedAnswer != nil && !savedAnswer!.isEmpty
        
        if let question = savedQuestion {
            currentQuestion = question
            currentAnswer = savedAnswer ?? ""
        } else if lastQuestionDate == todayString {
            // 오늘 이미 질문을 생성했지만 저장된 질문이 없는 경우
            showErrorState()
        } else {
            // 새로운 질문 생성
            generateNewQuestion()
        }
    }
    
    // MARK: - 새 질문 생성
    private func generateNewQuestion() {
        apiState = .loading
        
        // 실제 API 사용 또는 테스트 질문 사용
        let publisher = networkManager.generateTestQuestion() // 테스트용
        // let publisher = networkManager.generateQuestion() // 실제 API용
        
        publisher
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        apiState = .failure(error)
                        showAlert("질문 생성 실패", error.localizedDescription)
                    }
                },
                receiveValue: { question in
                    let normalizedToday = Calendar.current.startOfDay(for: today)
                    currentQuestion = question
                    hasQuestionForToday = true
                    apiState = .success(question)
                    dataManager.saveQuestion(question, for: normalizedToday)
                    showAlert("알림", "오늘의 질문이 생성되었습니다!")
                }
            )
            .store(in: &cancellables)
    }
    
    // MARK: - 답변 저장
    private func saveAnswer() {
        let trimmed = currentAnswer.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            showAlert("알림", "답변을 입력해주세요.")
            return
        }

        let normalizedToday = Calendar.current.startOfDay(for: today)

        // 답변 저장 전에 수정 여부를 미리 기록
        let isEdit = hasAnsweredToday

        dataManager.saveAnswer(trimmed, for: normalizedToday)
        hasAnsweredToday = true            // ← 저장 후 상태 변경

        let message = isEdit ? "답변이 수정되었습니다." : "답변이 저장되었습니다."
        showAlert("완료", message)
    }
    
    // MARK: - 상태 메시지
    private func getStatusMessage() -> String? {
        switch (hasQuestionForToday, hasAnsweredToday, apiState) {
        case (true, true, _):
            return "✅ 오늘의 답변을 완료했습니다. 답변을 수정할 수 있습니다."
        case (true, false, _):
            return "💭 오늘의 질문입니다. 답변을 작성해보세요!"
        case (false, _, .loading):
            return "🎲 오늘의 새로운 질문을 생성 중입니다..."
        case (false, _, .failure(_)):
            return "❌ 질문 생성에 실패했습니다. 다시 시도해주세요."
        default:
            return nil
        }
    }
    
    private func getMessageType() -> StatusMessageType {
        switch (hasQuestionForToday, hasAnsweredToday) {
        case (true, true):
            return .success
        case (true, false):
            return .info
        default:
            return .warning
        }
    }
    
    // MARK: - 에러 상태
    private func showErrorState() {
        apiState = .failure(.apiError("오늘은 이미 질문 생성 기회를 사용했습니다."))
        showAlert("알림", "오늘은 이미 질문 생성 기회를 사용했습니다. 내일 다시 시도해주세요.")
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            dismiss()
        }
    }
    
    private func showAlert(_ title: String, _ message: String) {
        alertTitle = title
        alertMessage = message
        showingAlert = true
    }
}

// MARK: - 헤더 뷰
struct DailyQHeaderView: View {
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy년 M월 d일"
        formatter.locale = Locale(identifier: "ko_KR")
        return formatter.string(from: Date())
    }
    
    var body: some View {
        VStack(spacing: 4) {
            Text("Daily Q")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(Color.letterColor)
            
            Text("새로운 소식")
                .font(.subheadline)
                .foregroundColor(Color.letterColor)
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .background(Color.mainColor)
        .cornerRadius(12)
        .padding(.bottom, 20)
    }
}

// MARK: - 상태 메시지 뷰
enum StatusMessageType {
    case success, info, warning, error
    
    var backgroundColor: Color {
        switch self {
        case .success: return Color.green.opacity(0.1)
        case .info: return Color.blue.opacity(0.1)
        case .warning: return Color.orange.opacity(0.1)
        case .error: return Color.red.opacity(0.1)
        }
    }
    
    var textColor: Color {
        switch self {
        case .success: return Color.green
        case .info: return Color.blue
        case .warning: return Color.orange
        case .error: return Color.red
        }
    }
}

struct StatusMessageView: View {
    let message: String
    let messageType: StatusMessageType
    
    var body: some View {
        Text(message)
            .font(.subheadline)
            .fontWeight(.medium)
            .foregroundColor(messageType.textColor)
            .padding(12)
            .frame(maxWidth: .infinity)
            .background(messageType.backgroundColor)
            .cornerRadius(8)
            .padding(.bottom, 16)
    }
}

// MARK: - 질문 섹션 뷰
struct QuestionSectionView: View {
    let question: String
    let state: APIState
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "questionmark.circle.fill")
                    .foregroundColor(Color.mainColor)
                
                Text("오늘의 질문")
                    .font(.headline)
                    .foregroundColor(Color.letterColor)
                
                Spacer()
            }
            
            Group {
                if case .loading = state {
                    HStack {
                        ProgressView()
                            .scaleEffect(0.8)
                        
                        Text("질문을 생성하고 있습니다...")
                            .foregroundColor(Color.blueGrayColor)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                } else if question.isEmpty {
                    Text("질문을 불러오는 중입니다...")
                        .foregroundColor(Color.blueGrayColor)
                } else {
                    Text(question)
                        .font(.title3)
                        .fontWeight(.medium)
                        .foregroundColor(Color.letterColor)
                        .lineLimit(nil)
                }
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.lightGrayColor)
            .cornerRadius(12)
        }
        .padding(.bottom, 20)
    }
}

// MARK: - 답변 입력 섹션
struct AnswerInputSection: View {
    @Binding var answer: String
    let isEnabled: Bool
    let onSave: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "pencil.circle.fill")
                    .foregroundColor(Color.mainColor)
                
                Text("나의 답변")
                    .font(.headline)
                    .foregroundColor(Color.letterColor)
                
                Spacer()
            }
            
            // 답변 입력 필드
            TextEditor(text: $answer)
                .font(.body)
                .foregroundColor(Color.letterColor)
                .padding(12)
                .background(Color.lightGrayColor)
                .cornerRadius(12)
                .frame(minHeight: 120)
                .disabled(!isEnabled)
                .overlay(
                    Group {
                        if answer.isEmpty && isEnabled {
                            Text("여기에 오늘의 답변을 작성해보세요")
                                .foregroundColor(Color.blueGrayColor)
                                .padding(.leading, 16)
                                .padding(.top, 20)
                                .allowsHitTesting(false)
                        }
                    },
                    alignment: .topLeading
                )
            
            // 저장 버튼
            Button(action: onSave) {
                Text(answer.isEmpty ? "답변 저장하기" : "답변 수정하기")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(isEnabled ? Color.mainColor : Color.grayColor)
                    .cornerRadius(8)
            }
            .disabled(!isEnabled)
        }
    }
}

// MARK: - 미리보기
struct DailyQView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            DailyQView()
        }
    }
}
