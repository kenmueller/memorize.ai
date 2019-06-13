import Foundation

var deckRatings = [DeckRating]()

class DeckRating {
	let id: String
	var rating: Int
	var review: String
	var date: Date
	
	init(id: String, rating: Int, review: String, date: Date) {
		self.id = id
		self.rating = rating
		self.review = review
		self.date = date
	}
	
	var deck: Deck? {
		return Deck.get(id)
	}
	
	var hasReview: Bool {
		return !review.isEmpty
	}
	
	var draft: RatingDraft? {
		return RatingDraft.get(id)
	}
	
	static func get(_ id: String) -> DeckRating? {
		return deckRatings.first { $0.id == id }
	}
}