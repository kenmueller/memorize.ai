import UIKit

class EditCardViewController: UIViewController {
	@IBOutlet weak var scrollView: UIScrollView!
	@IBOutlet weak var leftArrow: UIButton!
	@IBOutlet weak var rightArrow: UIButton!
	@IBOutlet weak var sideLabel: UILabel!
	@IBOutlet weak var swapViewBottomConstraint: NSLayoutConstraint!
	
	var cardEditor: CardEditorViewController?
	var cardPreview: CardPreviewViewController?
	var deck: Deck?
	var card: Card?
	var currentView = EditCardView.editor
	var currentSide = CardSide.front
	
	override func viewDidLoad() {
		super.viewDidLoad()
		disable(leftArrow)
		reloadRightBarButtonItem()
		guard let cardEditor = storyboard?.instantiateViewController(withIdentifier: "cardEditor") as? CardEditorViewController, let cardPreview = storyboard?.instantiateViewController(withIdentifier: "cardPreview") as? CardPreviewViewController else { return }
		self.cardEditor = addViewController(cardEditor) as? CardEditorViewController
		self.cardPreview = addViewController(cardPreview) as? CardPreviewViewController
		cardEditor.listen { side, text in
			cardPreview.update(side, text: text)
			self.reloadRightBarButtonItem()
		}
	}
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
		updateCurrentViewController()
	}
	
	func addViewController(_ viewController: UIViewController) -> UIViewController {
		scrollView.addSubview(viewController.view)
		addChild(viewController)
		viewController.didMove(toParent: self)
		return viewController
	}
	
	func reloadRightBarButtonItem() {
		func setRightBarButton(_ title: String, action: Selector) {
			navigationItem.setRightBarButton(UIBarButtonItem(title: title, style: .done, target: self, action: action), animated: false)
		}
		if card == nil {
			setRightBarButton("Create", action: #selector(create))
		} else {
			setRightBarButton("Save", action: #selector(save))
		}
		if cardEditor?.hasText ?? false {
			enableRightBarButtonItem()
		} else {
			 disableRightBarButtonItem()
		}
	}
	
	@objc func save() {
		guard let deck = deck, let card = card, let text = cardEditor?.trimmedText else { return }
		disableRightBarButtonItem()
		firestore.document("decks/\(deck.id)/cards/\(card.id)").updateData(["front": text.front, "back": text.back]) { error in
			guard error == nil else { return }
			buzz()
			self.reloadRightBarButtonItem()
		}
	}
	
	@objc func create() {
		guard let deck = deck, let text = cardEditor?.trimmedText else { return }
		let date = Date()
		disableRightBarButtonItem()
		firestore.collection("decks/\(deck.id)/cards").addDocument(data: ["front": text.front, "back": text.back, "created": date, "updated": date, "likes": 0, "dislikes": 0]) { error in
			guard error == nil else { return }
			buzz()
			self.reloadRightBarButtonItem()
		}
	}
	
	@objc func keyboardWillShow(notification: NSNotification) {
		guard let height = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue.height else { return }
		swapViewBottomConstraint.constant = height
		UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 0, options: .curveEaseOut, animations: view.layoutIfNeeded, completion: nil)
	}
	
	@objc func keyboardWillHide(notification: NSNotification) {
		swapViewBottomConstraint.constant = 0
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
		button.tintColor = .lightGray
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
					self.sideLabel.text = side.uppercased
					self.enable(self.rightArrow)
				}
				cardPreview?.load(.front)
			case .preview:
				cardPreview?.swap { side in
					self.sideLabel.text = side.uppercased
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
					self.sideLabel.text = side.uppercased
					self.enable(self.leftArrow)
				}
				cardPreview?.load(.back)
			case .preview:
				cardPreview?.swap { side in
					self.sideLabel.text = side.uppercased
					self.enable(self.leftArrow)
				}
				cardEditor?.load(.back)
			}
		case .back:
			return
		}
	}
}

enum EditCardView {
	case editor
	case preview
}
