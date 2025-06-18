//
//  DailyQApp.swift
//  DailyQ
//
//  Created by mac034 on 6/17/25.
//
import SwiftUI

@main
struct DailyQApp: App {
    var body: some Scene {
        WindowGroup {
            SplashView()
        }
    }
}

// MARK: - 스플래시 뷰
struct SplashView: View {
    @State private var isActive = false
    @State private var logoScale = 0.8
    @State private var logoOpacity = 0.0
    
    var body: some View {
        ZStack {
            Color("BackgroundColor")
                .ignoresSafeArea()
            
            VStack {
                // 로고 이미지
                Image("logo") 
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 150, height: 150)
                    .scaleEffect(logoScale)
                    .opacity(logoOpacity)
                
                // 앱 이름
                Text("Daily Q")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(Color("MainColor"))
                    .opacity(logoOpacity)
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.0)) {
                logoScale = 1.0
                logoOpacity = 1.0
            }
            
            // 2초 후 메인 화면으로 이동
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                withAnimation(.easeInOut(duration: 0.5)) {
                    isActive = true
                }
            }
        }
        .fullScreenCover(isPresented: $isActive) {
            ContentView()
        }
    }
}

// MARK: - 프로필 이미지 매니저
class ProfileImageManager: ObservableObject {
    @Published var selectedImage: UIImage?
    
    init() {
        loadSavedImage()
    }
    
    func saveImage(_ image: UIImage) {
        selectedImage = image
        
        // 이미지를 Documents 디렉토리에 저장
        if let data = image.jpegData(compressionQuality: 0.8) {
            let url = getDocumentsDirectory().appendingPathComponent("profile_image.jpg")
            try? data.write(to: url)
        }
    }
    
    func loadSavedImage() {
        let url = getDocumentsDirectory().appendingPathComponent("profile_image.jpg")
        if let data = try? Data(contentsOf: url),
           let image = UIImage(data: data) {
            selectedImage = image
        }
    }
    
    private func getDocumentsDirectory() -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
}

// MARK: - 메인 콘텐츠 뷰
struct ContentView: View {
    @State private var showingSideMenu = false
    @StateObject private var profileImageManager = ProfileImageManager()
    
    var body: some View {
        NavigationView {
            ZStack {
                // 배경색
                Color("BackgroundColor")
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // 커스텀 헤더
                    HeaderView(showingSideMenu: $showingSideMenu, profileImageManager: profileImageManager)
                    
                    // 메인 콘텐츠
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            // 헤더 이미지 카드
                            HeaderImageCard()
                            
                            // 기능 카드들
                            TodoCard()
                            DailyQCard()
                            CalendarCard()
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 20)
                    }
                }
            }
            .overlay(
                // 사이드 메뉴
                SideMenuView(isShowing: $showingSideMenu, profileImageManager: profileImageManager)
            )
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}

// MARK: - 헤더 뷰
struct HeaderView: View {
    @Binding var showingSideMenu: Bool
    @ObservedObject var profileImageManager: ProfileImageManager
    
    var body: some View {
        HStack {
            Text("Daily Q")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(Color("LetterColor"))
            
            Spacer()
            
            Button(action: {
                withAnimation(.spring()) {
                    showingSideMenu.toggle()
                }
            }) {
                ProfileImageView(profileImageManager: profileImageManager)
                    .frame(width: 40, height: 40)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color("LightGrayColor"))
    }
}

// MARK: - 프로필 이미지 뷰
struct ProfileImageView: View {
    @ObservedObject var profileImageManager: ProfileImageManager
    
    var body: some View {
        Group {
            if let image = profileImageManager.selectedImage {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 40, height: 40)
                    .clipShape(Circle())
            } else {
                Image(systemName: "person.circle.fill")
                    .font(.system(size: 30))
                    .foregroundColor(Color("MainColor"))
            }
        }
    }
}

// MARK: - 헤더 이미지 카드
struct HeaderImageCard: View {
    var body: some View {
        RoundedRectangle(cornerRadius: 12)
            .frame(height: 200)
            .overlay(
                // 임시로 그라데이션 배경 사용
                LinearGradient(
                    colors: [Color("MainColor"), Color("BlueColor")],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .overlay(
                    VStack {
                        Image(systemName: "sun.max.fill")
                            .font(.system(size: 50))
                            .foregroundColor(.white)
                        Text("Daily Q")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    }
                )
            )
            .cornerRadius(12)
    }
}

// MARK: - 투두 카드
struct TodoCard: View {
    var body: some View {
        NavigationLink(destination: TodoView()) {
            FeatureCard(
                icon: "checkmark.square.fill",
                iconColor: Color("BlueColor"),
                title: "TODOLIST",
                subtitle: "투두 리스트",
                description: "오늘 해야할일을 작성하거나 확인하세요."
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - 일일 질문 카드
struct DailyQCard: View {
    var body: some View {
        NavigationLink(destination: DailyQView()) {
            FeatureCard(
                icon: "questionmark.circle.fill",
                iconColor: Color("BlueColor"),
                title: "DAILY Q",
                subtitle: "오늘의 질문은?",
                description: "오늘의 질문에 대답하세요."
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - 캘린더 카드
struct CalendarCard: View {
    var body: some View {
        NavigationLink(destination: CalendarView()) {
            FeatureCard(
                icon: "calendar.circle.fill",
                iconColor: Color("BlueColor"),
                title: "Calendar",
                subtitle: "정보들을 한눈에 모아보세요!",
                description: "내가 대답한 질문과 해야할일을 한눈에 확인하세요."
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - 기능 카드 공통 컴포넌트
struct FeatureCard: View {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String
    let description: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // 타이틀 섹션
            HStack(alignment: .center, spacing: 12) {
                // 아이콘 배경
                RoundedRectangle(cornerRadius: 8)
                    .fill(iconColor.opacity(0.1))
                    .frame(width: 40, height: 40)
                    .overlay(
                        Image(systemName: icon)
                            .font(.system(size: 20))
                            .foregroundColor(iconColor)
                    )
                
                Text(title)
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(Color("BlueColor"))
                
                Spacer()
            }
            .padding(.bottom, 12)
            
            // 구분선
            Rectangle()
                .fill(Color("GrayColor"))
                .frame(height: 1)
                .padding(.bottom, 12)
            
            // 내용 섹션
            VStack(alignment: .leading, spacing: 4) {
                Text(subtitle)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(Color("LetterColor"))
                
                Text(description)
                    .font(.system(size: 14))
                    .foregroundColor(Color("BlueGrayColor"))
            }
        }
        .padding(16)
        .background(Color("LightGrayColor"))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 6, x: 0, y: 2)
    }
}

// MARK: - 프로필 설정 뷰
struct ProfileSettingsView: View {
    @ObservedObject var profileImageManager: ProfileImageManager
    @State private var showingImagePicker = false
    @State private var showingActionSheet = false
    @State private var sourceType: UIImagePickerController.SourceType = .photoLibrary
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                // 현재 프로필 이미지
                Button(action: {
                    showingActionSheet = true
                }) {
                    ZStack {
                        Circle()
                            .fill(Color("LightGrayColor"))
                            .frame(width: 150, height: 150)
                        
                        if let image = profileImageManager.selectedImage {
                            Image(uiImage: image)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 150, height: 150)
                                .clipShape(Circle())
                        } else {
                            Image(systemName: "person.fill")
                                .font(.system(size: 60))
                                .foregroundColor(Color("MainColor"))
                        }
                        
                        // 편집 아이콘
                        Circle()
                            .fill(Color("MainColor"))
                            .frame(width: 40, height: 40)
                            .overlay(
                                Image(systemName: "camera.fill")
                                    .foregroundColor(.white)
                                    .font(.system(size: 16))
                            )
                            .offset(x: 50, y: 50)
                    }
                }
                
                Text("프로필 사진을 설정하세요")
                    .font(.title3)
                    .foregroundColor(Color("LetterColor"))
                
                Spacer()
            }
            .padding()
            .navigationTitle("프로필 설정")
            .navigationBarItems(
                leading: Button("취소") {
                    presentationMode.wrappedValue.dismiss()
                }
            )
            .actionSheet(isPresented: $showingActionSheet) {
                ActionSheet(
                    title: Text("프로필 사진 변경"),
                    buttons: [
                        .default(Text("카메라")) {
                            sourceType = .camera
                            showingImagePicker = true
                        },
                        .default(Text("사진 라이브러리")) {
                            sourceType = .photoLibrary
                            showingImagePicker = true
                        },
                        .destructive(Text("사진 삭제")) {
                            profileImageManager.selectedImage = nil
                            // 저장된 파일도 삭제
                            let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("profile_image.jpg")
                            try? FileManager.default.removeItem(at: url)
                        },
                        .cancel()
                    ]
                )
            }
            .sheet(isPresented: $showingImagePicker) {
                ImagePicker(selectedImage: $profileImageManager.selectedImage, sourceType: sourceType) { image in
                    profileImageManager.saveImage(image)
                }
            }
        }
    }
}

// MARK: - 이미지 피커
struct ImagePicker: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage?
    let sourceType: UIImagePickerController.SourceType
    let onImageSelected: (UIImage) -> Void
    @Environment(\.presentationMode) var presentationMode
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = sourceType
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.selectedImage = image
                parent.onImageSelected(image)
            }
            parent.presentationMode.wrappedValue.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
}

// MARK: - 사이드 메뉴
struct SideMenuView: View {
    @Binding var isShowing: Bool
    @ObservedObject var profileImageManager: ProfileImageManager
    @State private var showingProfileSettings = false
    
    var body: some View {
        ZStack {
            if isShowing {
                // 배경 오버레이
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                    .contentShape(Rectangle())
                    .onTapGesture {
                        withAnimation(.spring()) {
                            isShowing = false
                        }
                    }
                
                // 사이드 메뉴
                HStack {
                    Spacer()
                    
                    VStack(spacing: 0) {
                        ProfileSection(profileImageManager: profileImageManager, showingProfileSettings: $showingProfileSettings)
                        
                        ScrollView {
                            VStack(spacing: 8) {
                                // 공지
                                NavigationLink(destination: NoticeView()) {
                                    MenuItemView(
                                        icon: "bell.fill",
                                        title: "공지",
                                        subtitle: "중요한 알림들"
                                    )
                                }
                                .onTapGesture {
                                    isShowing = false
                                }

                                // 답변 기록
                                NavigationLink(destination: AnswerView()) {
                                    MenuItemView(
                                        icon: "questionmark.circle.fill",
                                        title: "대답한 질문 모음",
                                        subtitle: "나의 답변 기록"
                                    )
                                }
                                .onTapGesture {
                                    isShowing = false
                                }

                                // 통계
                                NavigationLink(destination: StatsView()) {
                                    MenuItemView(
                                        icon: "chart.bar.fill",
                                        title: "통계",
                                        subtitle: "진행 상황 확인"
                                    )
                                }
                                .onTapGesture {
                                    isShowing = false
                                }

                                // 설정
                                NavigationLink(destination: SettingsView()) {
                                    MenuItemView(
                                        icon: "gearshape.fill",
                                        title: "설정",
                                        subtitle: "앱 환경설정"
                                    )
                                }
                                .onTapGesture {
                                    isShowing = false
                                }
                            }
                            .padding(16)
                        }
                        
                        Spacer()
                    }
                    .frame(width: 320)
                    .background(Color("BackgroundColor"))
                    .contentShape(Rectangle())
                    .onTapGesture { }
                }
                .transition(.move(edge: .trailing))
            }
        }
        .animation(.spring(), value: isShowing)
        .sheet(isPresented: $showingProfileSettings) {
            ProfileSettingsView(profileImageManager: profileImageManager)
        }
    }
}

// MARK: - 간단한 메뉴 아이템 뷰
struct MenuItemView: View {
    let icon: String
    let title: String
    let subtitle: String
    
    var body: some View {
        HStack(spacing: 16) {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color("MainColor").opacity(0.1))
                .frame(width: 44, height: 44)
                .overlay(
                    Image(systemName: icon)
                        .font(.system(size: 20))
                        .foregroundColor(Color("MainColor"))
                )
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(Color("LetterColor"))
                
                Text(subtitle)
                    .font(.system(size: 12))
                    .foregroundColor(Color("LetterColor"))
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.system(size: 14))
                .foregroundColor(Color("BlueGrayColor"))
        }
        .padding(16)
        .background(Color("LightGrayColor"))
        .cornerRadius(8)
    }
}

// MARK: - 프로필 섹션
struct ProfileSection: View {
    @ObservedObject var profileImageManager: ProfileImageManager
    @Binding var showingProfileSettings: Bool
    
    var body: some View {
        VStack(spacing: 16) {
            Button(action: {
                showingProfileSettings = true
            }) {
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.2))
                        .frame(width: 80, height: 80)
                    
                    if let image = profileImageManager.selectedImage {
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 80, height: 80)
                            .clipShape(Circle())
                    } else {
                        Image(systemName: "person.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.white)
                    }
                }
            }
            
            Text("프로필 설정")
                .font(.caption)
                .foregroundColor(.white.opacity(0.8))
            
            Spacer()
        }
        .frame(height: 200)
        .frame(maxWidth: .infinity)
        .background(
            LinearGradient(
                colors: [Color("MainColor"), Color("MainColor").opacity(0.8)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
    }
}

// MARK: - 미리보기
#Preview {
    ContentView()
}
