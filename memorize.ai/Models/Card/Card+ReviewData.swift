import Foundation
import Combine
import LoadingState

extension Card {
	final class ReviewData: ObservableObject, Identifiable, Equatable, Hashable {
		static let NUMBER_OF_CONSECUTIVE_CORRECT_ATTEMPTS_FOR_MASTERED = 6
		
		struct Prediction {
			let easy: Date
			let struggled: Date
			let forgot: Date
			
			init(functionResponse response: [String: Int]) {
				func dateForKey(_ key: String) -> Date {
					response[key].map {
						.init(timeIntervalSince1970: .init($0) / 1000)
					} ?? .now
				}
				
				easy = dateForKey("0")
				struggled = dateForKey("1")
				forgot = dateForKey("2")
			}
		}
		
		let parent: Card
		let userData: UserData?
		
		@Published var prediction: Prediction?
		@Published var predictionLoadingState = LoadingState()
		
		@Published var streak: Int
		@Published var rating: PerformanceRating?
		@Published var isNewlyMastered: Bool?
		
		init(parent: Card, userData: UserData?) {
			self.parent = parent
			self.userData = userData
			
			streak = userData?.streak ?? 0
		}
		
		var isNew: Bool {
			userData?.isNew ?? true
		}
		
		var didIncreaseStreak: Bool {
			rating?.isCorrect ?? false
		}
		
		func setRating(to rating: PerformanceRating) {
			self.rating = rating
			streak = rating.isCorrect ? streak + 1 : 0
			isNewlyMastered = streak == Self.NUMBER_OF_CONSECUTIVE_CORRECT_ATTEMPTS_FOR_MASTERED
		}
		
		func loadPrediction() -> Self {
			guard predictionLoadingState.isNone else { return self }
			
			predictionLoadingState.startLoading()
			
			onBackgroundThread {
				functions.httpsCallable("getCardPrediction").call(data: [
					"deck": self.parent.parent.id,
					"card": self.parent.id
				]).done { result in
					guard let data = result.data as? [String: Int] else {
						onMainThread {
							self.predictionLoadingState.fail(message: "Malformed response")
						}
						return
					}
					onMainThread {
						self.prediction = .init(functionResponse: data)
						self.predictionLoadingState.succeed()
					}
				}.catch { error in
					onMainThread {
						self.predictionLoadingState.fail(error: error)
					}
				}
			}
			
			return self
		}
		
		func predictionForRating(_ rating: PerformanceRating) -> Date? {
			switch rating {
			case .easy:
				return prediction?.easy
			case .struggled:
				return prediction?.struggled
			case .forgot:
				return prediction?.forgot
			}
		}
		
		func predictionMessageForRating(_ rating: PerformanceRating) -> String? {
			predictionForRating(rating).map { dueDate in
				"+\(Date().comparisonMessage(against: dueDate))"
			}
		}
		
		static func == (lhs: ReviewData, rhs: ReviewData) -> Bool {
			lhs.parent == rhs.parent
		}
		
		func hash(into hasher: inout Hasher) {
			hasher.combine(parent)
		}
	}
}
