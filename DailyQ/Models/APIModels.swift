//
//  APIModels.swift
//  DailyQ
//
//  Created by mac034 on 6/17/25.
//
import Foundation
import Combine

// MARK: - GPT API 모델들
struct GPTRequest: Codable {
    let model: String
    let messages: [GPTMessage]
    let maxTokens: Int
    let temperature: Double
    
    enum CodingKeys: String, CodingKey {
        case model, messages, temperature
        case maxTokens = "max_tokens"
    }
}

struct GPTMessage: Codable {
    let role: String
    let content: String
}

struct GPTResponse: Codable {
    let choices: [GPTChoice]
}

struct GPTChoice: Codable {
    let message: GPTMessage
}

// MARK: - 네트워크 에러
enum NetworkError: Error, LocalizedError {
    case invalidURL
    case noData
    case decodingError
    case apiError(String)
    case networkError(Error)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "잘못된 URL입니다."
        case .noData:
            return "데이터를 받지 못했습니다."
        case .decodingError:
            return "데이터 파싱에 실패했습니다."
        case .apiError(let message):
            return "API 오류: \(message)"
        case .networkError(let error):
            return "네트워크 오류: \(error.localizedDescription)"
        }
    }
}

// MARK: - 네트워크 매니저
class NetworkManager: ObservableObject {
    static let shared = NetworkManager()
    
    // GPT API 키 - 보안을 위해 실제 사용 시에는 환경변수나 별도 설정 파일에 저장하세요
    private let apiKey = "YOUR_API_KEY_HERE" // 실제 API 키로 교체하세요
    private let baseURL = "https://api.openai.com/v1/chat/completions"
    
    private var cancellables = Set<AnyCancellable>()
    
    private init() {}
    
    // MARK: - 질문 생성 API
    func generateQuestion() -> AnyPublisher<String, NetworkError> {
        // API 키가 설정되지 않았다면 테스트 질문 사용
        if apiKey == "YOUR_API_KEY_HERE" || apiKey.isEmpty {
            return generateTestQuestion()
        }
        
        guard let url = URL(string: baseURL) else {
            return Fail(error: NetworkError.invalidURL)
                .eraseToAnyPublisher()
        }
        
        let messages = [
            GPTMessage(role: "system", content: "일상적인 한줄 질문을 생성해줘. 너무 길지 않게. 자기계발이나 일상생활에 도움이 되는 질문으로 만들어줘."),
            GPTMessage(role: "user", content: "오늘의 질문을 만들어줘.")
        ]
        
        let request = GPTRequest(
            model: "gpt-3.5-turbo",
            messages: messages,
            maxTokens: 50,
            temperature: 0.8
        )
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.timeoutInterval = 30.0 // 타임아웃 설정
        
        do {
            urlRequest.httpBody = try JSONEncoder().encode(request)
        } catch {
            return Fail(error: NetworkError.networkError(error))
                .eraseToAnyPublisher()
        }
        
        return URLSession.shared.dataTaskPublisher(for: urlRequest)
            .timeout(.seconds(30), scheduler: DispatchQueue.main) // 타임아웃 추가
            .map(\.data)
            .decode(type: GPTResponse.self, decoder: JSONDecoder())
            .map { response in
                guard let content = response.choices.first?.message.content else {
                    return "질문 생성에 실패했습니다."
                }
                return content.trimmingCharacters(in: .whitespacesAndNewlines)
            }
            .catch { error -> AnyPublisher<String, NetworkError> in
                // API 오류가 발생하면 테스트 질문으로 fallback
                return self.generateTestQuestion()
            }
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
    
    // MARK: - 테스트용 질문 생성 (API 키가 없을 때)
    func generateTestQuestion() -> AnyPublisher<String, NetworkError> {
        let testQuestions = [
            "오늘 가장 감사했던 일은 무엇인가요?",
            "내일 꼭 하고 싶은 한 가지는 무엇인가요?",
            "최근에 새로 배운 것이 있다면 무엇인가요?",
            "오늘 나를 웃게 만든 것은 무엇인가요?",
            "가장 소중한 사람에게 전하고 싶은 말은?",
            "나의 장점 중 하나를 말해보세요.",
            "스트레스를 받을 때 어떻게 해소하나요?",
            "꿈꾸는 미래의 모습은 어떤가요?",
            "오늘 하루 중 가장 기억에 남는 순간은?",
            "나만의 특별한 취미나 관심사는 무엇인가요?",
            "최근에 읽은 책이나 본 영화 중 인상 깊었던 것은?",
            "나를 행복하게 만드는 작은 것들은 무엇인가요?",
            "어려운 상황에서 나는 어떻게 극복하나요?",
            "친구들이 말하는 나의 매력은 무엇일까요?",
            "올해 이루고 싶은 목표가 있다면?",
            "나만의 스트레스 해소법이 있나요?",
            "가족이나 친구들과의 소중한 추억이 있다면?",
            "내가 좋아하는 계절과 그 이유는?",
            "최근에 도전해보고 싶은 새로운 것이 있나요?",
            "나를 위해 오늘 할 수 있는 작은 선물은?"
        ]
        
        let randomQuestion = testQuestions.randomElement() ?? "오늘 어떤 하루를 보내셨나요?"
        
        // 실제 API 호출처럼 약간의 지연 시간 추가
        return Just(randomQuestion)
            .delay(for: .seconds(Double.random(in: 0.5...1.5)), scheduler: DispatchQueue.main)
            .setFailureType(to: NetworkError.self)
            .eraseToAnyPublisher()
    }
}

// MARK: - API 응답 상태
enum APIState {
    case idle
    case loading
    case success(String)
    case failure(NetworkError)
}
