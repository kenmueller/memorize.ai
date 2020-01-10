import SwiftUI
import WebView

struct LearnViewCardContent: View {
	@EnvironmentObject var model: LearnViewModel
	
	@ObservedObject var card: Card
	
	@State var toggleIconDegrees = 0.0
	
	var body: some View {
		ZStack(alignment: .bottomTrailing) {
			WebView(
				html: card.renderSide(model.currentSide),
				baseURL: WEB_VIEW_BASE_URL
			)
			.cornerRadius(5)
			CardToggleButton(
				image: .greenSwapIcon,
				circleDimension: 40,
				fontSize: 13,
				side: $model.currentSide,
				degrees: $toggleIconDegrees
			)
			.padding([.trailing, .bottom], 10)
			.opacity(*model.isWaitingForRating)
		}
	}
}

#if DEBUG
struct LearnViewCardContent_Previews: PreviewProvider {
	static var previews: some View {
		LearnViewCardContent(
			card: PREVIEW_CURRENT_STORE.user.decks[0].previewCards[0]
		)
		.environmentObject(LearnViewModel(
			deck: PREVIEW_CURRENT_STORE.user.decks.first!,
			section: nil
		))
	}
}
#endif