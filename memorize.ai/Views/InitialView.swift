import SwiftUI

struct InitialView: View {
	var body: some View {
		NavigationView {
			VStack {
				Spacer()
				ZStack(alignment: .bottom) {
					InitialViewBottomGradient()
					InitialViewBottomButtons()
				}
			}
			.background(Color.lightGrayBackground)
			.edgesIgnoringSafeArea(.top)
		}
	}
}

#if DEBUG
struct InitialView_Previews: PreviewProvider {
	static var previews: some View {
		InitialView()
	}
}
#endif
