import SwiftUI
import FirebaseFirestore
import LoadingState

struct ReviewView: View {
	@EnvironmentObject var currentStore: CurrentStore
	
	static let POP_UP_SLIDE_DURATION = 0.25
	static let CARD_SLIDE_DURATION = 0.25
	static let XP_CHANCE = 0.5
	
	typealias PopUpData = (
		emoji: String,
		message: String,
		badge: (text: String, color: Color)?
	)
	
	let user: User
	let deck: Deck?
	let section: Deck.Section?
	
	@State var numberOfTotalCards = 0
	
	@State var current: Card.ReviewData?
	@State var currentIndex = -1
	@State var currentSide = Card.Side.front
	
	@State var currentSection: Deck.Section?
	
	@State var isWaitingForRating = false
	
	@State var shouldShowRecap = false
	
	@State var popUpOffset: CGFloat = -SCREEN_SIZE.width
	@State var popUpData: PopUpData?
	
	@State var cardOffset: CGFloat = 0
	
	@State var currentCardLoadingState = LoadingState()
	@State var reviewCardLoadingState = LoadingState()
	
	@State var xpGained = 0
	
	@State var isReviewingNewCards = false
	@State var cards = [Card.ReviewData]()
	@State var initialXP = 0
	
	init(user: User, deck: Deck?, section: Deck.Section?) {
		self.user = user
		self.deck = deck
		self.section = section
		
		_currentSection = .init(initialValue: deck?.unsectionedSection)
	}
	
	var currentCard: Card? {
		current?.parent
	}
	
	var isPopUpShowing: Bool {
		popUpOffset.isZero
	}
	
	var shouldGainXP: Bool {
		.random(in: 0...1) <= Self.XP_CHANCE
	}
	
	func loadNumberOfTotalCards() {
		numberOfTotalCards =
			section?.numberOfDueCards
				?? deck?.userData?.numberOfDueCards
					?? user.numberOfDueCards
	}
	
	func showPopUp(
		emoji: String,
		message: String,
		badge: (text: String, color: Color)?,
		duration: Double = 1,
		onCentered: (() -> Void)? = nil,
		completion: (() -> Void)? = nil
	) {
		popUpData = (emoji, message, badge)
		withAnimation(.easeOut(duration: Self.POP_UP_SLIDE_DURATION)) {
			popUpOffset = 0
		}
		waitUntil(duration: Self.POP_UP_SLIDE_DURATION) {
			onCentered?()
			waitUntil(duration: duration) {
				withAnimation(.easeIn(duration: Self.POP_UP_SLIDE_DURATION)) {
					self.popUpOffset = SCREEN_SIZE.width
				}
				waitUntil(duration: Self.POP_UP_SLIDE_DURATION) {
					self.popUpOffset = -SCREEN_SIZE.width
					completion?()
				}
			}
		}
	}
	
	func showPopUp(
		forRating rating: Card.PerformanceRating,
		badge: (text: String, color: Color)?,
		onCentered: (() -> Void)? = nil,
		completion: (() -> Void)? = nil
	) {
		switch rating {
		case .easy:
			showPopUp(emoji: "🎉", message: "Great!", badge: badge, onCentered: onCentered, completion: completion)
		case .struggled:
			showPopUp(emoji: "😎", message: "Good luck!", badge: badge, onCentered: onCentered, completion: completion)
		case .forgot:
			showPopUp(emoji: "😕", message: "Better luck next time!", badge: badge, onCentered: onCentered, completion: completion)
		}
	}
	
	func skipCard() {
		withAnimation(.easeIn(duration: 0.3)) {
			isWaitingForRating = false
		}
		showPopUp(emoji: "😕", message: "Skipped!", badge: nil, onCentered: {
			self.loadNextCard()
		})
	}
	
	func waitForRating() {
		withAnimation(.easeIn(duration: 0.3)) {
			isWaitingForRating = true
		}
		withAnimation(.easeIn(duration: Self.CARD_SLIDE_DURATION)) {
			cardOffset = -SCREEN_SIZE.width
		}
		waitUntil(duration: Self.CARD_SLIDE_DURATION) {
			self.currentSide = .back
			self.cardOffset = SCREEN_SIZE.width
			withAnimation(.easeOut(duration: Self.CARD_SLIDE_DURATION)) {
				self.cardOffset = 0
			}
		}
	}
	
	func rateCurrentCard(withRating rating: Card.PerformanceRating) {
		guard let current = current else { return }
		let card = current.parent
		
		cards.append(current)
		
		let gainXP = shouldGainXP
		
		if gainXP {
			xpGained++
		}
		
		reviewCardLoadingState.startLoading()
		card.review(rating: rating, viewTime: 0 /* TODO: Calculate this */).done { isNewlyMastered in
			current.isNewlyMastered = isNewlyMastered
			self.reviewCardLoadingState.succeed()
		}.catch { error in
			showAlert(title: "Unable to rate card", message: "You will move on to the next card")
			self.reviewCardLoadingState.fail(error: error)
			self.loadNextCard()
		}
		
		withAnimation(.easeIn(duration: 0.3)) {
			isWaitingForRating = false
		}
		
		let shouldShowRecap = currentIndex == numberOfTotalCards - 1
		
		showPopUp(
			forRating: rating,
			badge: gainXP
				? ("+1 xp", Card.PerformanceRating.easy.badgeColor.opacity(0.16))
				: nil,
			onCentered: {
				if shouldShowRecap { return }
				self.loadNextCard()
			},
			completion: {
				if gainXP {
					self.user.documentReference.updateData([
						"xp": FieldValue.increment(1 as Int64)
					]) as Void
				}
				
				guard shouldShowRecap else { return }
				self.shouldShowRecap = true
			}
		)
	}
	
	func failCurrentCardLoadingState(withError error: Error) {
		showAlert(title: "Unable to load card", message: "You will move on to the next card")
		currentCardLoadingState.fail(error: error)
		loadNextCard()
	}
	
	func updateCurrentCard(to card: Card, isNew: Bool) {
		current = Card.ReviewData(
			parent: card,
			isNew: isNew
		).loadPrediction()
		currentSide = .front
		currentCardLoadingState.succeed()
	}
	
	func loadNextCard(
		incrementCurrentIndex: Bool = true,
		startLoading: Bool = true,
		continueFromSnapshot: Bool = true
	) {
		if incrementCurrentIndex {
			currentIndex++
		}
		
		if startLoading {
			currentCardLoadingState.startLoading()
		}
		
		if let section = section {
			let deck = section.parent
			
			func updateCurrentCard(withId cardId: String, isNew: Bool) {
				if let card = (section.cards.first { $0.id == cardId }) {
					self.updateCurrentCard(to: card, isNew: isNew)
				} else {
					firestore
						.document("decks/\(deck.id)/cards/\(cardId)")
						.getDocument()
						.done { snapshot in
							self.updateCurrentCard(
								to: .init(
									snapshot: snapshot,
									parent: deck
								),
								isNew: isNew
							)
						}
						.catch(failCurrentCardLoadingState)
				}
			}
			
			if isReviewingNewCards {
				user.documentReference
					.collection("decks/\(deck.id)/cards")
					.whereField("section", isEqualTo: section.id)
					.whereField("new", isEqualTo: true)
					.start(afterDocument: continueFromSnapshot ? currentCard?.snapshot : nil)
					.limit(to: 1)
					.getDocuments()
					.done { snapshot in
						if let cardId = snapshot.documents.first?.documentID {
							updateCurrentCard(withId: cardId, isNew: true)
						} else {
							self.shouldShowRecap = true
						}
					}
					.catch(failCurrentCardLoadingState)
			} else {
				user.documentReference
					.collection("decks/\(deck.id)/cards")
					.whereField("section", isEqualTo: section.id)
					.whereField("new", isEqualTo: false)
					.whereField("due", isLessThanOrEqualTo: Date())
					.order(by: "due")
					.start(afterDocument: continueFromSnapshot ? currentCard?.snapshot : nil)
					.limit(to: 1)
					.getDocuments()
					.done { snapshot in
						if let cardId = snapshot.documents.first?.documentID {
							updateCurrentCard(withId: cardId, isNew: false)
						} else {
							self.isReviewingNewCards = true
							self.loadNextCard(
								incrementCurrentIndex: false,
								startLoading: false,
								continueFromSnapshot: false
							)
						}
					}
					.catch(failCurrentCardLoadingState)
			}
		} else if let deck = deck {
			guard let currentSection = currentSection else {
				self.shouldShowRecap = true
				return
			}
			
			guard deck.sectionsLoadingState.didSucceed else {
				deck.loadSections { error in
					if let error = error {
						self.failCurrentCardLoadingState(withError: error)
					} else {
						self.loadNextCard(
							incrementCurrentIndex: false,
							startLoading: false,
							continueFromSnapshot: continueFromSnapshot
						)
					}
				}
				return
			}
			
			func updateCurrentCard(withId cardId: String, sectionId: String, isNew: Bool) {
				self.currentSection = deck.section(withId: sectionId)
				
				if let card = deck.card(withId: cardId, sectionId: sectionId) {
					self.updateCurrentCard(to: card, isNew: isNew)
				} else {
					firestore
						.document("decks/\(deck.id)/cards/\(cardId)")
						.getDocument()
						.done { snapshot in
							self.updateCurrentCard(
								to: .init(
									snapshot: snapshot,
									parent: deck
								),
								isNew: isNew
							)
						}
						.catch(failCurrentCardLoadingState)
				}
			}
			
			if isReviewingNewCards {
				user.documentReference
					.collection("decks/\(deck.id)/cards")
					.whereField("section", isEqualTo: currentSection.id)
					.whereField("new", isEqualTo: true)
					.start(afterDocument: continueFromSnapshot ? currentCard?.snapshot : nil)
					.limit(to: 1)
					.getDocuments()
					.done { snapshot in
						if let cardId = snapshot.documents.first?.documentID {
							updateCurrentCard(
								withId: cardId,
								sectionId: currentSection.id,
								isNew: true
							)
						} else {
							func setCurrentSection(to section: Deck.Section) {
								self.currentSection = section
								self.loadNextCard(
									incrementCurrentIndex: false,
									startLoading: false,
									continueFromSnapshot: false
								)
							}
							
							let unlockedSections = deck.unlockedSections
							
							if currentSection.isUnsectioned {
								if let newCurrentSection = unlockedSections.first {
									setCurrentSection(to: newCurrentSection)
								} else {
									self.shouldShowRecap = true
								}
							} else if
								let currentSectionIndex = unlockedSections.firstIndex(of: currentSection),
								let newCurrentSection = unlockedSections[safe: currentSectionIndex + 1]
							{
								setCurrentSection(to: newCurrentSection)
							} else {
								self.shouldShowRecap = true
							}
						}
					}
					.catch(failCurrentCardLoadingState)
			} else {
				user.documentReference
					.collection("decks/\(deck.id)/cards")
					.whereField("new", isEqualTo: false)
					.whereField("due", isLessThanOrEqualTo: Date())
					.order(by: "due")
					.start(afterDocument: continueFromSnapshot ? currentCard?.snapshot : nil)
					.limit(to: 1)
					.getDocuments()
					.done { snapshot in
						if let userData = snapshot.documents.first.map(Card.UserData.init) {
							updateCurrentCard(
								withId: userData.id,
								sectionId: userData.sectionId,
								isNew: false
							)
						} else {
							self.isReviewingNewCards = true
							self.loadNextCard(
								incrementCurrentIndex: false,
								startLoading: false,
								continueFromSnapshot: false
							)
						}
					}
					.catch(failCurrentCardLoadingState)
			}
		} else {
			print("REVIEWING_ALL_CARDS") // TODO: Review all cards
		}
	}
	
	var body: some View {
		GeometryReader { geometry in
			ZStack {
				ZStack(alignment: .top) {
					Group {
						Color.lightGrayBackground
						HomeViewTopGradient(
							addedHeight: geometry.safeAreaInsets.top
						)
					}
					.edgesIgnoringSafeArea(.all)
					VStack {
						ReviewViewTopControls(currentIndex: self.currentIndex, numberOfTotalCards: self.numberOfTotalCards, skipCard: self.skipCard)
							.padding(.horizontal, 23)
						ReviewViewCardSection(deck: self.deck, section: self.section, currentSection: self.currentSection, current: self.current, cardOffset: self.cardOffset, isWaitingForRating: self.isWaitingForRating, currentSide: self.$currentSide)
							.padding(.top, 6)
							.padding(.horizontal, 8)
						ReviewViewFooter(rateCurrentCard: self.rateCurrentCard, current: self.current, isWaitingForRating: self.isWaitingForRating)
							.padding(.top, 16)
					}
				}
				.blur(radius: self.isPopUpShowing ? 5 : 0)
				.onTapGesture {
					if
						self.isWaitingForRating ||
						self.current == nil
					{ return }
					self.waitForRating()
				}
				.disabled(self.isPopUpShowing)
				ReviewViewPopUp(data: self.popUpData, popUpOffset: self.popUpOffset)
				NavigateTo(
					ReviewRecapView()
						.navigationBarRemoved(),
					when: self.$shouldShowRecap
				)
			}
		}
		.onAppear {
			self.initialXP = self.currentStore.user.xp
			self.loadNumberOfTotalCards()
			self.loadNextCard()
		}
	}
}

#if DEBUG
struct ReviewView_Previews: PreviewProvider {
	static var previews: some View {
		let model = ReviewViewModel(
			user: PREVIEW_CURRENT_STORE.user,
			deck: nil,
			section: nil
		)
		model.isWaitingForRating = true
		return Text("")
			.environmentObject(PREVIEW_CURRENT_STORE)
			.environmentObject(model)
	}
}
#endif
