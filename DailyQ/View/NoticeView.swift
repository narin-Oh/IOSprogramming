import SwiftUI

struct NoticeView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
            Color("BackgroundColor")
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // 헤더 (간단한 버전)
                NoticeHeaderView()
                
                // 공지사항 목록
                ScrollView {
                    VStack(spacing: 16) {
                        // 공지사항 아이템들
                        NoticeItemView(
                            title: "앱 업데이트 안내",
                            date: "2025.06.15",
                            content: "새로운 기능이 추가되었습니다. 더 나은 사용자 경험을 위해 업데이트해주세요."
                        )
                        
                        NoticeItemView(
                            title: "서비스 점검 안내",
                            date: "2025.06.10",
                            content: "서비스 안정화를 위한 정기 점검이 있었습니다. 이용에 불편을 드려 죄송합니다."
                        )
                        
                        NoticeItemView(
                            title: "새로운 질문 카테고리 추가",
                            date: "2025.06.05",
                            content: "더 다양한 주제의 질문들을 만나보세요. 새로운 카테고리가 추가되었습니다."
                        )
                        
                        NoticeItemView(
                            title: "Daily Q iOS 버전 출시",
                            date: "2025.06.01",
                            content: "드디어 iOS 버전이 출시되었습니다! 안드로이드와 동일한 기능을 iOS에서도 만나보세요."
                        )
                        
                        NoticeItemView(
                            title: "개인정보 보호정책 업데이트",
                            date: "2025.05.25",
                            content: "개인정보 보호를 위한 정책이 업데이트되었습니다. 자세한 내용은 설정에서 확인해주세요."
                        )
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 20)
                }
                
                Spacer()
            }
        }
        .navigationBarHidden(false)
        .navigationBarBackButtonHidden(false)
        .navigationTitle("공지사항")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - 간단한 헤더 뷰
struct NoticeHeaderView: View {
    var body: some View {
        VStack(spacing: 4) {
            Text("공지사항")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(Color("LetterColor"))
            
            Text("Daily Q의 새로운 소식")
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

// MARK: - 공지사항 아이템 뷰
struct NoticeItemView: View {
    let title: String
    let date: String
    let content: String
    
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // 제목과 날짜
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(Color("LetterColor"))
                    
                    Text(date)
                        .font(.caption)
                        .foregroundColor(Color("GrayColor"))
                }
                
                Spacer()
                
                // 확장/축소 아이콘
                Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                    .font(.system(size: 14))
                    .foregroundColor(Color("BlueGrayColor"))
            }
            
            // 내용 (확장 시에만 표시)
            if isExpanded {
                Text(content)
                    .font(.body)
                    .foregroundColor(Color("BlueGrayColor"))
                    .padding(.top, 8)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(16)
        .background(Color("LightGrayColor"))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
        .onTapGesture {
            withAnimation(.easeInOut(duration: 0.3)) {
                isExpanded.toggle()
            }
        }
    }
}

// MARK: - 미리보기
#Preview {
    NavigationView {
        NoticeView()
    }
}
