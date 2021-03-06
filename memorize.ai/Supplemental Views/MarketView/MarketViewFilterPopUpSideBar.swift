import SwiftUI

struct MarketViewFilterPopUpSideBar: View {
	@Binding var filterPopUpSideBarSelection: MarketView.FilterPopUpSideBarSelection
	
	var topicsButton: some View {
		MarketViewFilterPopUpSideBarButton(
			selectedIcon: {
				Image.selectedFilterSideBarTopicsIcon
					.resizable()
					.renderingMode(.original)
					.aspectRatio(contentMode: .fit)
			},
			unselectedIcon: {
				Image.filterSideBarTopicsIcon
					.resizable()
					.renderingMode(.original)
					.aspectRatio(contentMode: .fit)
			},
			isSelected: filterPopUpSideBarSelection == .topics
		) {
			self.filterPopUpSideBarSelection = .topics
		}
	}
	
	var ratingButton: some View {
		MarketViewFilterPopUpSideBarButton(
			selectedIcon: {
				Image.selectedFilterSideBarRatingIcon
					.resizable()
					.renderingMode(.original)
					.aspectRatio(contentMode: .fit)
			},
			unselectedIcon: {
				Image.filterSideBarRatingIcon
					.resizable()
					.renderingMode(.original)
					.aspectRatio(contentMode: .fit)
			},
			isSelected: filterPopUpSideBarSelection == .rating
		) {
			self.filterPopUpSideBarSelection = .rating
		}
	}
	
	var downloadsButton: some View {
		MarketViewFilterPopUpSideBarButton(
			selectedIcon: {
				Image.selectedFilterSideBarDownloadsIcon
					.resizable()
					.renderingMode(.original)
					.aspectRatio(contentMode: .fit)
			},
			unselectedIcon: {
				Image.filterSideBarDownloadsIcon
					.resizable()
					.renderingMode(.original)
					.aspectRatio(contentMode: .fit)
			},
			isSelected: filterPopUpSideBarSelection == .downloads
		) {
			self.filterPopUpSideBarSelection = .downloads
		}
	}
	
	var body: some View {
		HStack(spacing: 0) {
			VStack(spacing: 0) {
				topicsButton
				ratingButton
				downloadsButton
				Spacer()
			}
			.frame(width: 50)
			.background(Color.lightGrayBackground)
			Rectangle()
				.foregroundColor(literal: #colorLiteral(red: 0.8470588235, green: 0.8470588235, blue: 0.8470588235, alpha: 1))
				.frame(width: 1)
		}
		.frame(height: MarketViewFilterPopUp.contentHeight)
	}
}

#if DEBUG
struct MarketViewFilterPopUpSideBar_Previews: PreviewProvider {
	static var previews: some View {
		MarketViewFilterPopUpSideBar(
			filterPopUpSideBarSelection: .constant(.topics)
		)
	}
}
#endif
