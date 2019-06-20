import UIKit

class EditCardViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate {
	@IBOutlet weak var collectionView: UICollectionView!
	@IBOutlet weak var loadingView: UIView!
	@IBOutlet weak var loadingActivityIndicatory: UIActivityIndicatorView!
	@IBOutlet weak var leftArrow: UIButton!
	@IBOutlet weak var rightArrow: UIButton!
	@IBOutlet weak var sideLabel: UILabel!
	@IBOutlet weak var toolbarBottomConstraint: NSLayoutConstraint!
	@IBOutlet weak var addUploadButton: UIButton!
	@IBOutlet weak var addUploadButtonWidthConstraint: NSLayoutConstraint!
	@IBOutlet weak var removeDraftButton: UIButton!
	@IBOutlet weak var removeDraftButtonWidthConstraint: NSLayoutConstraint!
	@IBOutlet weak var removeDraftActivityIndicator: UIActivityIndicatorView!
	@IBOutlet weak var deleteCardButton: UIButton!
	@IBOutlet weak var deleteCardButtonWidthConstraint: NSLayoutConstraint!
	@IBOutlet weak var deleteCardActivityIndicator: UIActivityIndicatorView!
	
	var cardEditor: CardEditorViewController?
	var cardPreview: CardPreviewViewController?
	var deck: Deck?
	var card: Card?
	var currentView = EditCardView.editor
	var currentSide = CardSide.front
	var lastPublishedText: (front: String, back: String)?
	var views = [UIView]()
	
	override func viewDidLoad() {
		super.viewDidLoad()
		let flowLayout = UICollectionViewFlowLayout()
		flowLayout.itemSize = CGSize(width: collectionView.bounds.width, height: collectionView.bounds.height)
		flowLayout.scrollDirection = .horizontal
		collectionView.collectionViewLayout = flowLayout
		navigationItem.title = "\(card == nil ? "New" : "Edit") Card"
		disable(leftArrow)
		guard let cardEditor = storyboard?.instantiateViewController(withIdentifier: "cardEditor") as? CardEditorViewController, let cardPreview = storyboard?.instantiateViewController(withIdentifier: "cardPreview") as? CardPreviewViewController else { return }
		self.cardEditor = cardEditor
		self.cardPreview = cardPreview
		views = [cardEditor.view, cardPreview.view]
		loadText()
		reloadRightBarButtonItem()
		reloadToolbar(animated: false)
		guard let id = id, let deck = deck else { return }
		cardEditor.listen { side, text in
			if let card = self.card {
				if let draft = card.draft {
					firestore.document("users/\(id)/cardDrafts/\(draft.id)").updateData([side.rawValue: text])
				} else {
					let text = cardEditor.text
					firestore.collection("users/\(id)/cardDrafts").addDocument(data: ["deck": deck.id, "card": card.id, "front": text.front, "back": text.back])
				}
			} else if let draft = deck.cardDraft {
				firestore.document("users/\(id)/cardDrafts/\(draft.id)").updateData([side.rawValue: text])
			} else {
				let text = cardEditor.text
				firestore.collection("users/\(id)/cardDrafts").addDocument(data: ["deck": deck.id, "front": text.front, "back": text.back])
			}
			cardPreview.update(side, text: text)
			self.reloadRightBarButtonItem()
		}
	}
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		ChangeHandler.update { change in
			if change == .cardDraftAdded || change == .cardDraftRemoved {
				self.reloadToolbar()
			}
		}
		NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
		updateCurrentViewController()
	}
	
	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		super.prepare(for: segue, sender: self)
		if let uploadsVC = segue.destination as? UploadsViewController {
			uploadsVC.completion = { upload in
				self.startLoading()
				upload.url { url, error in
					self.stopLoading()
					if error == nil, let url = url {
						self.cardEditor?.current.add(upload.toMarkdown(url.absoluteString))
						self.showNotification("Added \(upload.type == .audio ? "audio file" : upload.type.rawValue)", type: .success)
					} else {
						self.showNotification("Unable to add \(upload.type.rawValue). Please try again", type: .error)
					}
				}
			}
		}
	}
	
	func startLoading() {
		loadingView.isHidden = false
		loadingActivityIndicatory.startAnimating()
	}
	
	func stopLoading() {
		loadingActivityIndicatory.stopAnimating()
		loadingView.isHidden = true
	}
	
	func loadText() {
		guard let deck = deck, let cardEditor = cardEditor, let cardPreview = cardPreview else { return }
		if let card = card {
			lastPublishedText = card.text
			let draft = CardDraft.get(cardId: card.id)
			cardEditor.update(.front, text: draft?.front ?? card.front)
			cardPreview.update(.front, text: draft?.front ?? card.front)
			cardEditor.update(.back, text: draft?.back ?? card.back)
			cardPreview.update(.back, text: draft?.back ?? card.back)
		} else if let draft = CardDraft.get(deckId: deck.id) {
			cardEditor.update(.front, text: draft.front)
			cardPreview.update(.front, text: draft.front)
			cardEditor.update(.back, text: draft.back)
			cardPreview.update(.back, text: draft.back)
		}
	}
	
	func reloadRightBarButtonItem() {
		navigationItem.setRightBarButton(UIBarButtonItem(title: "Publish", style: .done, target: self, action: card == nil ? #selector(publishNew) : #selector(publishEdit)), animated: false)
		guard let cardEditor = cardEditor, cardEditor.hasText else { return disableRightBarButtonItem() }
		guard let lastPublishedText = lastPublishedText else { return enableRightBarButtonItem() }
		if cardEditor.trimmedText == lastPublishedText {
			disableRightBarButtonItem()
		} else {
			enableRightBarButtonItem()
		}
	}
	
	@objc func publishNew() {
		guard let deck = deck, let text = cardEditor?.trimmedText else { return }
		let date = Date()
		disableRightBarButtonItem()
		firestore.collection("decks/\(deck.id)/cards").addDocument(data: ["front": text.front, "back": text.back, "created": date, "updated": date, "likes": 0, "dislikes": 0]) { error in
			if error == nil, let id = id {
				if let draft = CardDraft.get(deckId: deck.id) {
					firestore.document("users/\(id)/cardDrafts/\(draft.id)").delete()
				}
				self.navigationController?.popViewController(animated: true)
			} else {
				self.showNotification("There was an error publishing the card. Please try again", type: .error)
				self.enableRightBarButtonItem()
			}
		}
	}
	
	@objc func publishEdit() {
		guard let deck = deck, let card = card, let text = cardEditor?.trimmedText else { return }
		disableRightBarButtonItem()
		firestore.document("decks/\(deck.id)/cards/\(card.id)").updateData(["front": text.front, "back": text.back]) { error in
			if error == nil, let id = id {
				if let draft = CardDraft.get(cardId: card.id) {
					firestore.document("users/\(id)/cardDrafts/\(draft.id)").delete()
				}
				self.lastPublishedText = text
				buzz()
			} else {
				self.showNotification("There was an error publishing the card. Please try again", type: .error)
				self.enableRightBarButtonItem()
			}
		}
	}
	
	@objc func keyboardWillShow(notification: NSNotification) {
		guard let height = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue.height else { return }
		let offset = height - 30
		let halfOffset = offset / 2
		cardEditor?.frontTextViewTopConstraint.constant = halfOffset
		cardEditor?.backTextViewTopConstraint.constant = halfOffset
		cardEditor?.frontTextViewBottomConstraint.constant = halfOffset
		cardEditor?.backTextViewBottomConstraint.constant = halfOffset
		cardPreview?.frontWebViewTopConstraint.constant = halfOffset
		cardPreview?.backWebViewTopConstraint.constant = halfOffset
		cardPreview?.frontWebViewBottomConstraint.constant = halfOffset
		cardPreview?.backWebViewBottomConstraint.constant = halfOffset
		cardEditor?.view.layoutIfNeeded()
		cardPreview?.view.layoutIfNeeded()
		toolbarBottomConstraint.constant = offset
		UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 0, options: .curveEaseOut, animations: view.layoutIfNeeded, completion: nil)
	}
	
	@objc func keyboardWillHide(notification: NSNotification) {
		cardEditor?.frontTextViewTopConstraint.constant = 0
		cardEditor?.backTextViewTopConstraint.constant = 0
		cardEditor?.frontTextViewBottomConstraint.constant = 0
		cardEditor?.backTextViewBottomConstraint.constant = 0
		cardPreview?.frontWebViewTopConstraint.constant = 0
		cardPreview?.backWebViewTopConstraint.constant = 0
		cardPreview?.frontWebViewBottomConstraint.constant = 0
		cardPreview?.backWebViewBottomConstraint.constant = 0
		cardEditor?.view.layoutIfNeeded()
		cardPreview?.view.layoutIfNeeded()
		toolbarBottomConstraint.constant = 0
		UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 0, options: .curveLinear, animations: view.layoutIfNeeded, completion: nil)
	}
	
	func enableRightBarButtonItem() {
		guard let button = navigationItem.rightBarButtonItem else { return }
		button.isEnabled = true
		button.tintColor = .white
	}
	
	func disableRightBarButtonItem() {
		guard let button = navigationItem.rightBarButtonItem else { return }
		button.isEnabled = false
		button.tintColor = #colorLiteral(red: 0.9841352105, green: 0.9841352105, blue: 0.9841352105, alpha: 1)
	}
	
	func enable(_ button: UIButton) {
		button.isEnabled = true
		button.tintColor = .darkGray
	}
	
	func disable(_ button: UIButton) {
		button.isEnabled = false
		button.tintColor = .lightGray
	}
	
	@IBAction func left() {
		disable(leftArrow)
		sideLabel.text = "~~~"
		switch currentSide {
		case .front:
			return
		case .back:
			switch currentView {
			case .editor:
				cardEditor?.swap { side in
					self.updateSide(side)
					self.enable(self.rightArrow)
				}
				cardPreview?.load(.front)
			case .preview:
				cardPreview?.swap { side in
					self.updateSide(side)
					self.enable(self.rightArrow)
				}
				cardEditor?.load(.front)
			}
		}
	}
	
	@IBAction func right() {
		disable(rightArrow)
		sideLabel.text = "~~~"
		switch currentSide {
		case .front:
			switch currentView {
			case .editor:
				cardEditor?.swap { side in
					self.updateSide(side)
					self.enable(self.leftArrow)
				}
				cardPreview?.load(.back)
			case .preview:
				cardPreview?.swap { side in
					self.updateSide(side)
					self.enable(self.leftArrow)
				}
				cardEditor?.load(.back)
			}
		case .back:
			return
		}
	}
	
	@IBAction func addUpload() {
		performSegue(withIdentifier: "addUpload", sender: self)
	}
	
	@IBAction func removeDraft() {
		guard let id = id else { return }
		let alertController = UIAlertController(title: "Are you sure?", message: "This action cannot be undone", preferredStyle: .alert)
		alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
		alertController.addAction(UIAlertAction(title: "Remove", style: .destructive) { _ in
			self.setRemoveDraftLoading(true)
			self.showNotification("Removing draft...", type: .normal)
			if let card = self.card, let draft = card.draft {
				firestore.document("users/\(id)/cardDrafts/\(draft.id)").delete { error in
					self.setRemoveDraftLoading(false)
					self.showNotification(error == nil ? "Removed draft" : "Unable to remove draft. Please try again", type: error == nil ? .success : .error)
					self.cardEditor?.update(.front, text: card.front)
					self.cardEditor?.update(.back, text: card.back)
				}
			} else if let draft = self.deck?.cardDraft {
				firestore.document("users/\(id)/cardDrafts/\(draft.id)").delete { error in
					self.setRemoveDraftLoading(false)
					if error == nil {
						self.navigationController?.popViewController(animated: true)
					} else {
						self.showNotification("Unable to remove draft. Please try again", type: .error)
					}
				}
			}
		})
		present(alertController, animated: true, completion: nil)
	}
	
	@IBAction func deleteCard() {
		guard let deck = deck, let card = card else { return }
		let draft = card.draft
		let alertController = UIAlertController(title: "Are you sure?", message: "The card\(draft == nil ? " and your draft" : "") will be deleted. This action cannot be undone", preferredStyle: .alert)
		alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
		alertController.addAction(UIAlertAction(title: "Delete", style: .destructive) { _ in
			self.setDeleteCardLoading(true)
			let draftMessage = draft == nil ? "" : " and draft"
			self.showNotification("Deleting card\(draftMessage)...", type: .normal)
			firestore.document("decks/\(deck.id)/cards/\(card.id)").delete { error in
				if error == nil {
					if let draft = draft, let id = id {
						firestore.document("users/\(id)/cardDrafts/\(draft.id)").delete { error in
							self.setDeleteCardLoading(false)
							if error == nil {
								self.navigationController?.popViewController(animated: true)
							} else {
								self.showNotification("Unable to delete draft. Please try again", type: .error)
							}
						}
					} else {
						self.setDeleteCardLoading(false)
						self.navigationController?.popViewController(animated: true)
					}
				} else {
					self.setDeleteCardLoading(false)
					self.showNotification("Unable to delete card\(draftMessage). Please try again", type: .error)
				}
			}
		})
		present(alertController, animated: true, completion: nil)
	}
	
	func setRemoveDraftLoading(_ isLoading: Bool) {
		removeDraftButton.isEnabled = !isLoading
		removeDraftButton.setTitle(isLoading ? nil : "Remove draft", for: .normal)
		if isLoading {
			removeDraftActivityIndicator.startAnimating()
		} else {
			removeDraftActivityIndicator.stopAnimating()
		}
	}
	
	func setDeleteCardLoading(_ isLoading: Bool) {
		deleteCardButton.isEnabled = !isLoading
		deleteCardButton.setTitle(isLoading ? nil : "Delete card", for: .normal)
		if isLoading {
			deleteCardActivityIndicator.startAnimating()
		} else {
			deleteCardActivityIndicator.stopAnimating()
		}
	}
	
	func reloadToolbar(animated: Bool = true) {
		guard let deck = deck else { return }
		let oneThirdWidth = (view.bounds.width - 40) / 3
		let halfWidth = view.bounds.width / 2 - 15
		let fullWidth = view.bounds.width - 20
		if let card = card {
			if card.hasDraft {
				addUploadButtonWidthConstraint.constant = oneThirdWidth
				removeDraftButtonWidthConstraint.constant = oneThirdWidth
				deleteCardButtonWidthConstraint.constant = oneThirdWidth
			} else {
				addUploadButtonWidthConstraint.constant = halfWidth
				removeDraftButtonWidthConstraint.constant = 0
				deleteCardButtonWidthConstraint.constant = halfWidth
			}
		} else if deck.hasCardDraft {
			addUploadButtonWidthConstraint.constant = halfWidth
			removeDraftButtonWidthConstraint.constant = halfWidth
			deleteCardButtonWidthConstraint.constant = 0
		} else {
			addUploadButtonWidthConstraint.constant = fullWidth
			removeDraftButtonWidthConstraint.constant = 0
			deleteCardButtonWidthConstraint.constant = 0
		}
		UIView.animate(withDuration: animated ? 0.15 : 0, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 0, options: .curveEaseIn, animations: view.layoutIfNeeded, completion: nil)
	}
	
	func updateSide(_ side: CardSide) {
		sideLabel.text = side.uppercased
		currentSide = side
	}
	
	func getText() -> String {
		let isFront = currentSide == .front
		if let card = card {
			if let draft = card.draft {
				return isFront ? draft.front : draft.back
			} else {
				return isFront ? card.front : card.back
			}
		} else if let draft = deck?.cardDraft {
			return isFront ? draft.front : draft.back
		} else {
			return ""
		}
	}
	
	@objc func playAudio() {
		Audio.stop()
		Card.playAudio(getText())
	}
	
	func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
		return views.count
	}
	
	func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
		let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath)
		let element = views[indexPath.item]
		element.frame.size.height = cell.frame.height
		cell.addSubview(element)
		return cell
	}
	
	func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
		let pageWidth = scrollView.frame.size.width
		let newCurrentView: EditCardView = Int(floor((scrollView.contentOffset.x - pageWidth / 2) / pageWidth) + 1) == 0 ? .editor : .preview
		switch newCurrentView {
		case currentView:
			return
		case .editor:
			Audio.stop()
			reloadRightBarButtonItem()
		case .preview:
			playAudio()
			navigationItem.setRightBarButton(UIBarButtonItem(barButtonSystemItem: .refresh, target: self, action: #selector(playAudio)), animated: false)
		}
		currentView = newCurrentView
	}
}

enum EditCardView {
	case editor
	case preview
}
