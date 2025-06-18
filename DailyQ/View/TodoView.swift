//
//  TodoView.swift
//  DailyQ
//
//  Created by mac034 on 6/17/25.
//
import SwiftUI

struct TodoView: View {
    @StateObject private var dataManager = DataManager.shared
    @State private var currentDate = Date()
    @State private var todoText = ""
    @State private var todoList: [TodoItem] = []
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
            Color("BackgroundColor")
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
                    
                    Text("할일관리")
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
                
                // 커스텀 헤더
                TodoHeaderView(currentDate: currentDate)
                
                // 할 일 추가 섹션
                TodoInputSection(
                    todoText: $todoText,
                    onAdd: addTodo
                )
                
                // 할 일 목록 또는 빈 상태
                if todoList.isEmpty {
                    EmptyTodoView()
                } else {
                    TodoListView(
                        todoList: $todoList,
                        onDelete: deleteTodo,
                        onToggle: toggleTodo
                    )
                }
                
                Spacer()
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            loadTodoList()
        }
        .alert("알림", isPresented: $showingAlert) {
            Button("확인", role: .cancel) { }
        } message: {
            Text(alertMessage)
        }
    }
    
    // MARK: - 할 일 추가
    private func addTodo() {
        let trimmedText = todoText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedText.isEmpty else {
            showAlert("할 일을 입력해주세요")
            return
        }
        
        let newTodo = TodoItem(text: trimmedText, isCompleted: false)
        todoList.append(newTodo)
        todoText = ""
        saveTodoList()
        showAlert("할 일이 추가되었습니다")
    }
    
    // MARK: - 할 일 삭제
    private func deleteTodo(at indexSet: IndexSet) {
        todoList.remove(atOffsets: indexSet)
        saveTodoList()
        showAlert("할 일이 삭제되었습니다")
    }
    
    // MARK: - 할 일 완료 토글
    private func toggleTodo(at index: Int) {
        todoList[index].isCompleted.toggle()
        saveTodoList()
    }
    
    // MARK: - 데이터 로드/저장 (DataManager 사용)
    private func loadTodoList() {
        let normalizedDate = Calendar.current.startOfDay(for: currentDate)
        todoList = dataManager.getTodoList(for: normalizedDate)
    }
    
    private func saveTodoList() {
        let normalizedDate = Calendar.current.startOfDay(for: currentDate)
        dataManager.saveTodoList(todoList, for: normalizedDate)
    }
    
    private func showAlert(_ message: String) {
        alertMessage = message
        showingAlert = true
    }
}

// MARK: - 헤더 뷰 (메인 컨텐츠 헤더)
struct TodoHeaderView: View {
    let currentDate: Date
    
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy년 M월 d일"
        formatter.locale = Locale(identifier: "ko_KR")
        return formatter.string(from: currentDate)
    }
    
    var body: some View {
        VStack(spacing: 4) {
            Text("나의 할 일")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(Color("LetterColor"))
            
            Text(formattedDate)
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

// MARK: - 할 일 입력 섹션
struct TodoInputSection: View {
    @Binding var todoText: String
    let onAdd: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            // 입력 필드
            TextField("새로운 할 일을 입력하세요", text: $todoText)
                .padding(12)
                .background(Color("LightGrayColor"))
                .cornerRadius(8)
                .onSubmit {
                    onAdd()
                }
            
            // 추가 버튼
            Button(action: onAdd) {
                Image(systemName: "plus")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
                    .frame(width: 48, height: 48)
                    .background(Color("MainColor"))
                    .cornerRadius(24)
            }
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 20)
    }
}

// MARK: - 할 일 목록 뷰
struct TodoListView: View {
    @Binding var todoList: [TodoItem]
    let onDelete: (IndexSet) -> Void
    let onToggle: (Int) -> Void
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 8) {
                ForEach(todoList.indices, id: \.self) { index in
                    TodoItemView(
                        todo: $todoList[index],
                        onToggle: { onToggle(index) }
                    )
                }
                .onDelete(perform: onDelete)
            }
            .padding(.horizontal, 16)
        }
    }
}

// MARK: - 할 일 아이템 뷰 (가독성 개선)
struct TodoItemView: View {
    @Binding var todo: TodoItem
    let onToggle: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            // 체크박스
            Button(action: onToggle) {
                Image(systemName: todo.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 24))
                    .foregroundColor(todo.isCompleted ? Color("MainColor") : Color("BlueGrayColor"))
            }
            
            // 할 일 텍스트 (완료된 항목의 가독성 개선)
            Text(todo.text)
                .font(.system(size: 16))
                .foregroundColor(todo.isCompleted ? Color("LetterColor").opacity(0.6) : Color("LetterColor"))
                .strikethrough(todo.isCompleted, color: Color("LetterColor").opacity(0.8))
                .animation(.easeInOut(duration: 0.2), value: todo.isCompleted)
            
            Spacer()
            
            // 완료 상태 표시
            if todo.isCompleted {
                Text("완료")
                    .font(.caption)
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color("MainColor"))
                    .cornerRadius(12)
            }
        }
        .padding(16)
        .background(todo.isCompleted ? Color("LightGrayColor").opacity(0.7) : Color("LightGrayColor"))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
        .scaleEffect(todo.isCompleted ? 0.98 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: todo.isCompleted)
    }
}

// MARK: - 빈 상태 뷰
struct EmptyTodoView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "list.bullet.clipboard")
                .font(.system(size: 60))
                .foregroundColor(Color("BlueGrayColor").opacity(0.3))
            
            VStack(spacing: 8) {
                Text("할 일이 없습니다")
                    .font(.headline)
                    .foregroundColor(Color("BlueGrayColor"))
                
                Text("새로운 할 일을 추가해보세요!")
                    .font(.subheadline)
                    .foregroundColor(Color("BlueGrayColor"))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.top, 100)
    }
}

// MARK: - 미리보기
#Preview {
    NavigationView {
        TodoView()
    }
}
