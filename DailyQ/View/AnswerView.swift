//
//  AnswerView.swift
//  DailyQ
//
//  Created by mac034 on 6/17/25.
//
import SwiftUI

enum AnswerFilter: String, CaseIterable {
    case all = "전체"
    case month = "이번 달"
    case week = "이번 주"
}

struct AnswerView: View {
    @StateObject private var dataManager = DataManager.shared
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedFilter: AnswerFilter = .all
    @State private var answers: [AnswerData] = []
    @State private var filteredAnswers: [AnswerData] = []
    @State private var selectedAnswer: AnswerData?
    @State private var showingDetailModal = false
    
    var body: some View {
        ZStack {
            Color("BackgroundColor")
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // 헤더
                AnswerHeaderView()
                
                // 필터 버튼들
                FilterButtonsView(selectedFilter: $selectedFilter, onFilterChanged: applyFilter)
                
                // 답변 목록
                if filteredAnswers.isEmpty {
                    EmptyAnswerView(filter: selectedFilter)
                } else {
                    ScrollView {
                        VStack(spacing: 16) {
                            ForEach(filteredAnswers, id: \.id) { answer in
                                AnswerItemView(answer: answer) {
                                    selectedAnswer = answer
                                    showingDetailModal = true
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 20)
                    }
                }
                
                Spacer()
            }
        }
        .navigationBarHidden(false)
        .navigationBarBackButtonHidden(false)
        .navigationTitle("나의 답변")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            loadAnswers()
        }
        .sheet(isPresented: $showingDetailModal) {
            if let answer = selectedAnswer {
                AnswerDetailModal(answer: answer)
            }
        }
    }
    
    private func loadAnswers() {
        answers = dataManager.getAllAnswers()
        applyFilter()
    }
    
    private func applyFilter() {
        let calendar = Calendar.current
        let now = Date()
        
        switch selectedFilter {
        case .all:
            filteredAnswers = answers
        case .month:
            let startOfMonth = calendar.dateInterval(of: .month, for: now)?.start ?? now
            filteredAnswers = answers.filter { $0.date >= startOfMonth }
        case .week:
            let oneWeekAgo = calendar.date(byAdding: .day, value: -7, to: now) ?? now
            filteredAnswers = answers.filter { $0.date >= oneWeekAgo }
        }
    }
}

// MARK: - 헤더 뷰
struct AnswerHeaderView: View {
    var body: some View {
        VStack(spacing: 4) {
            Text("나의 답변")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(Color("LetterColor"))
            
            Text("지금까지 작성한 답변들")
                .font(.subheadline)
                .foregroundColor(Color("LetterColor"))
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .background(Color("MainColor"))
        .cornerRadius(12)
        .padding(.horizontal, 16)
        .padding(.bottom, 20)
    }
}

// MARK: - 필터 버튼들
struct FilterButtonsView: View {
    @Binding var selectedFilter: AnswerFilter
    let onFilterChanged: () -> Void
    
    var body: some View {
        HStack(spacing: 8) {
            ForEach(AnswerFilter.allCases, id: \.self) { filter in
                FilterButton(
                    title: filter.rawValue,
                    isSelected: selectedFilter == filter
                ) {
                    selectedFilter = filter
                    onFilterChanged()
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 16)
    }
}

struct FilterButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(Color("LetterColor"))
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? Color("MainColor") : Color("LightGrayColor"))
                .cornerRadius(8)
        }
    }
}

// MARK: - 답변 아이템 뷰
struct AnswerItemView: View {
    let answer: AnswerData
    let onTap: () -> Void
    
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy년 M월 d일"
        formatter.locale = Locale(identifier: "ko_KR")
        return formatter.string(from: answer.date)
    }
    
    private var previewText: String {
        if answer.answer.count > 50 {
            return String(answer.answer.prefix(50)) + "..."
        }
        return answer.answer
    }
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {
                // 날짜
                Text(formattedDate)
                    .font(.caption)
                    .foregroundColor(Color("GrayColor"))
                
                // 질문
                Text(answer.question)
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(Color("LetterColor"))
                    .multilineTextAlignment(.leading)
                
                // 답변 미리보기
                Text(previewText)
                    .font(.body)
                    .foregroundColor(Color("LetterColor"))
                    .multilineTextAlignment(.leading)
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .background(Color("LightGrayColor"))
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - 빈 상태 뷰
struct EmptyAnswerView: View {
    let filter: AnswerFilter
    
    private var emptyMessage: String {
        switch filter {
        case .all:
            return "아직 작성한 답변이 없습니다.\n오늘의 질문에 답변해보세요!"
        case .month:
            return "이번 달에 작성한 답변이 없습니다."
        case .week:
            return "이번 주에 작성한 답변이 없습니다."
        }
    }
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "doc.text")
                .font(.system(size: 60))
                .foregroundColor(Color("LetterColor").opacity(0.5))
            
            Text(emptyMessage)
                .font(.body)
                .foregroundColor(Color("LetterColor"))
                .multilineTextAlignment(.center)
                .lineLimit(nil)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.top, 100)
    }
}

// MARK: - 답변 상세 모달
struct AnswerDetailModal: View {
    let answer: AnswerData
    @Environment(\.dismiss) private var dismiss
    
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy년 M월 d일"
        formatter.locale = Locale(identifier: "ko_KR")
        return formatter.string(from: answer.date)
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color("BackgroundColor")
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        // 날짜
                        Text(formattedDate)
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundColor(Color("MainColor"))
                        
                        // 질문
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "questionmark.circle.fill")
                                    .foregroundColor(Color("MainColor"))
                                Text("질문")
                                    .font(.headline)
                                    .foregroundColor(Color("LetterColor"))
                            }
                            
                            Text(answer.question)
                                .font(.body)
                                .foregroundColor(Color("LetterColor"))
                                .padding()
                                .background(Color("LightGrayColor"))
                                .cornerRadius(12)
                        }
                        
                        // 답변
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "pencil.circle.fill")
                                    .foregroundColor(Color("MainColor"))
                                Text("답변")
                                    .font(.headline)
                                    .foregroundColor(Color("LetterColor"))
                            }
                            
                            Text(answer.answer)
                                .font(.body)
                                .foregroundColor(Color("LetterColor"))
                                .padding()
                                .background(Color("LightGrayColor"))
                                .cornerRadius(12)
                        }
                        
                        Spacer()
                    }
                    .padding(20)
                }
            }
            .navigationTitle("답변 상세")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("닫기") {
                        dismiss()
                    }
                    .foregroundColor(Color("MainColor"))
                }
            }
        }
    }
}

// MARK: - 미리보기
struct AnswerView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            AnswerView()
        }
    }
}
