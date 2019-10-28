import Combine
import FirebaseAuth
import GoogleSignIn
import PromiseKit

final class GoogleSignInButtonModel: ObservableObject {
	@Published var loadingState = LoadingState.none
	@Published var shouldShowActivityIndicator = false
	@Published var shouldProgressToHomeView = false
	@Published var shouldProgressToChooseTopicsView = false
	
	var user: User?
	
	func logIn() {
		loadingState = .loading()
		GIDSignIn.completion = logInCompletion
		GIDSignIn.sharedInstance().presentingViewController =
			UIApplication.shared.windows.last?.rootViewController
		GIDSignIn.sharedInstance().signIn()
	}
	
	func logInCompletion(promise: Promise<AuthDataResult>) {
		shouldShowActivityIndicator = true
		promise.done { result in
			let user = result.user
			guard
				let email = user.email,
				let additionalInfo = result.additionalUserInfo
			else { return }
			let newUser = User(
				id: user.uid,
				name: user.displayName ?? "Unknown",
				email: email
			)
			self.user = newUser
			self.createUser(from: newUser).done {
				if additionalInfo.isNewUser {
					self.shouldProgressToChooseTopicsView = true
				} else {
					self.shouldProgressToHomeView = true
				}
				self.loadingState = .success()
			}.catch { error in
				self.loadingState = .failure(
					message: error.localizedDescription
				)
			}
		}.catch { error in
			self.loadingState = .failure(
				message: error.localizedDescription
			)
		}
	}
	
	func createUser(from user: User) -> Promise<Void> {
		firestore.document("users/\(user.id)").setData([
			"name": user.name,
			"email": user.email
		])
	}
}