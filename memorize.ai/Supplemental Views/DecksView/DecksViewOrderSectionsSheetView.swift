import SwiftUI

struct DecksViewOrderSectionsSheetView: View {
	@ObservedObject var deck: Deck
	
	func onSectionMove(from source: Int, to destination: Int) {
		if source == destination { return }
		
		let maxIndex = deck.sections.count - 1
		
		let source = min(source, maxIndex)
		let destination = min(destination, maxIndex)
		
		let batch = firestore.batch()
		batch.updateData(
			["index": destination],
			forDocument: deck.sections[source].documentReference
		)
		batch.updateData(
			["index": source],
			forDocument: deck.sections[destination].documentReference
		)
		batch.commit()
		deck.sections.swapAt(source, destination)
	}
	
	var body: some View {
		List {
			ForEach(deck.sections) { section in
				Text(section.name)
			}
			.onMove { sources, destination in
				guard let source = sources.first else { return }
				self.onSectionMove(from: source, to: destination)
			}
		}
		.environment(\.editMode, .constant(.active))
	}
}

#if DEBUG
struct DecksViewOrderSectionsSheetView_Previews: PreviewProvider {
	static var previews: some View {
		DecksViewOrderSectionsSheetView(
			deck: PREVIEW_CURRENT_STORE.user.decks.first!
		)
	}
}
#endif
