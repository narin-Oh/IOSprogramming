//
//  StatsView.swift
//  DailyQ
//
//  Created by mac034 on 6/17/25.
//
import SwiftUI

struct StatsView: View {
    @StateObject private var dataManager = DataManager.shared
    @Environment(\.dismiss) private var dismiss
    
    @State private var statsData: StatsData?
    
    var body: some View {
        ZStack {
            Color("BackgroundColor")
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // 헤더
                StatsHeaderView()
                
                if let stats = statsData {
                    ScrollView {
                        VStack(spacing: 16) {
                            // 전체 답변 수 카드
                            TotalAnswersCard(totalAnswers: stats.totalAnswers)
                            
                            // 이번 달/주 통계
                            HStack(spacing: 16) {
                                MonthWeekStatsCard(
                                    title: "이번 달",
                                    count: stats.thisMonthAnswers
                                )
                                
                                MonthWeekStatsCard(
                                    title: "이번 주",
                                    count: stats.thisWeekAnswers
                                )
                            }
                            
                            // 연속 작성 기록
                            StreakStatsCard(
                                currentStreak: stats.currentStreak,
                                maxStreak: stats.maxStreak
                            )
                            
                            // 월별 작성 현황
                            MonthlyStatsCard(monthlyStats: stats.monthlyStats)
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 20)
                    }
                } else {
                    Spacer()
                    ProgressView("통계를 계산하고 있습니다...")
                        .foregroundColor(Color("BlueGrayColor"))
                    Spacer()
                }
            }
        }
        .navigationBarHidden(false)
        .navigationBarBackButtonHidden(false)
        .navigationTitle("통계")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            loadStats()
        }
    }
    
    private func loadStats() {
        // 약간의 지연을 주어 자연스럽게 로딩
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            statsData = dataManager.getStatsData()
        }
    }
}

// MARK: - 헤더 뷰
struct StatsHeaderView: View {
    var body: some View {
        VStack(spacing: 4) {
            Text("통계")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(Color("LetterColor"))
            
            Text("나의 작성 현황")
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

// MARK: - 전체 답변 수 카드
struct TotalAnswersCard: View {
    let totalAnswers: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("전체 답변 수")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(Color("LetterColor"))
            
            Text("\(totalAnswers)개")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(Color("LetterColor"))
            
            Text("지금까지 작성한 총 답변 개수입니다")
                .font(.caption)
                .foregroundColor(Color("GrayColor"))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(Color("LightGrayColor"))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
}

// MARK: - 월/주 통계 카드
struct MonthWeekStatsCard: View {
    let title: String
    let count: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline)
                .foregroundColor(Color("LetterColor"))
            
            Text("\(count)개")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(Color("LetterColor"))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color("LightGrayColor"))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
}

// MARK: - 연속 기록 카드
struct StreakStatsCard: View {
    let currentStreak: Int
    let maxStreak: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("연속 작성 기록")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(Color("LetterColor"))
            
            HStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("현재 연속")
                        .font(.caption)
                        .foregroundColor(Color("GrayColor"))
                    
                    Text("\(currentStreak)일")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(Color("LetterColor"))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("최고 기록")
                        .font(.caption)
                        .foregroundColor(Color("GrayColor"))
                    
                    Text("\(maxStreak)일")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(Color("LetterColor"))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(16)
        .background(Color("LightGrayColor"))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
}

// MARK: - 월별 통계 카드
struct MonthlyStatsCard: View {
    let monthlyStats: [(month: String, count: Int)]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("월별 작성 현황")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(Color("LetterColor"))
            
            if monthlyStats.isEmpty {
                Text("데이터가 없습니다")
                    .font(.subheadline)
                    .foregroundColor(Color("BlueGrayColor"))
                    .frame(maxWidth: .infinity)
            } else {
                HStack(spacing: 20) {
                    ForEach(Array(monthlyStats.enumerated()), id: \.offset) { index, stat in
                        VStack(spacing: 4) {
                            Text(stat.month)
                                .font(.subheadline)
                                .foregroundColor(Color("GrayColor"))
                            
                            Text("\(stat.count)개")
                                .font(.headline)
                                .fontWeight(.bold)
                                .foregroundColor(Color("LetterColor"))
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
            }
        }
        .padding(16)
        .background(Color("LightGrayColor"))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
}

// MARK: - 미리보기
struct StatsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            StatsView()
        }
    }
}
