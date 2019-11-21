import SwiftUI

struct MarketViewTopControls: View {
	@Binding var searchText: String
	
	var body: some View {
		HStack(spacing: 20) {
			ShowSideBarButton {
				HamburgerMenu()
			}
			CustomRectangle(
				background: HomeViewTopControls.searchBarBackgroundColor,
				cornerRadius: 24
			) {
				HStack(spacing: 10) {
					Image.whiteMagnifyingGlass
						.resizable()
						.renderingMode(.original)
						.aspectRatio(contentMode: .fit)
						.frame(width: 14)
					TextField("", text: $searchText)
						.font(.muli(.regular, size: 17))
						.foregroundColor(.white)
						.padding(.vertical)
						.offset(y: 1)
					Spacer()
				}
				.padding(.horizontal)
				.frame(height: 48)
			}
		}
	}
}

#if DEBUG
struct MarketViewTopControls_Previews: PreviewProvider {
	static var previews: some View {
		MarketViewTopControls(searchText: .constant(""))
	}
}
#endif