import SwiftUI

struct LearnRecapViewCardPerformanceRowCardCell: View {
	let card: Card.LearnData
	let rating: Card.PerformanceRating
	
	func ratingCountBadge(forRating rating: Card.PerformanceRating) -> some View {
		CustomRectangle(
			background: rating == card.mostFrequentRating
				? Color(#colorLiteral(red: 0.03529411765, green: 0.6156862745, blue: 0.4117647059, alpha: 1)).opacity(0.1)
				: .lightGrayBackground
		) {
			Text("\(rating.title): \(card.countOfRating(rating).formatted)")
				.font(.muli(.bold, size: 14))
				.foregroundColor(.darkGray)
				.padding(.horizontal, 12)
				.padding(.vertical, 4)
		}
	}
	
	var body: some View {
		CustomRectangle(
			background: Color.white,
			borderColor: rating.badgeColor,
			borderWidth: 1,
			cornerRadius: 8
		) {
			VStack(alignment: .leading) {
				LearnRecapViewCardPerformanceRowCardCellContent(
					card: card.parent
				)
				HStack {
					ForEach([.easy, .struggled, .forgot], id: \.self) { rating in
						self.ratingCountBadge(forRating: rating)
					}
				}
			}
			.padding(8)
		}
	}
}

#if DEBUG
struct LearnRecapViewCardPerformanceRowCardCell_Previews: PreviewProvider {
	static var previews: some View {
		LearnRecapViewCardPerformanceRowCardCell(
			card: .init(
				parent: PREVIEW_CURRENT_STORE.user.decks[0].previewCards[0]
			),
			rating: .easy
		)
	}
}
#endif