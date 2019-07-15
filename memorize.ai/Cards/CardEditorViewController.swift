import UIKit

class CardEditorViewController: UIViewController, UITextViewDelegate {
	@IBOutlet weak var frontTextView: UITextView!
	@IBOutlet weak var frontTextViewTopConstraint: NSLayoutConstraint!
	@IBOutlet weak var frontTextViewBottomConstraint: NSLayoutConstraint!
	@IBOutlet weak var backTextView: UITextView!
	@IBOutlet weak var backTextViewTopConstraint: NSLayoutConstraint!
	@IBOutlet weak var backTextViewBottomConstraint: NSLayoutConstraint!
	
	private var listener: ((CardSide, String) -> Void)?
	
	override func viewDidLoad() {
		super.viewDidLoad()
		frontTextView.setKeyboard(.advanced)
		backTextView.setKeyboard(.advanced)
	}
	
	var text: (front: String, back: String) {
		return (frontTextView.text, backTextView.text)
	}
	
	var trimmedText: (front: String, back: String) {
		return (frontTextView.text.trim(), backTextView.text.trim())
	}
	
	var hasText: Bool {
		return !(trimmedText.front.isEmpty || trimmedText.back.isEmpty)
	}
	
	var hasAnyText: Bool {
		return !(trimmedText.front.isEmpty && trimmedText.back.isEmpty)
	}
	
	var current: UITextView {
		return frontTextView.isHidden ? backTextView : frontTextView
	}
	
	private func focusTextView(forSide side: CardSide) {
		switch side {
		case .front:
			frontTextView.becomeFirstResponder()
		case .back:
			backTextView.becomeFirstResponder()
		}
	}
	
	func update(_ side: CardSide, text: String) {
		switch side {
		case .front:
			frontTextView.text = text
		case .back:
			backTextView.text = text
		}
	}
	
	func listen(handler: @escaping (CardSide, String) -> Void) {
		listener = handler
	}
	
	func scrollToTop(animated: Bool = false) {
		[frontTextView, backTextView].forEach { $0.setContentOffset(.zero, animated: animated) }
	}
	
	func scrollToCursorPosition() {
		let textView = current
		guard let cursorPosition = textView.selectedTextRange?.start else { return }
		textView.scrollRectToVisible(textView.caretRect(for: cursorPosition), animated: true)
	}
	
	func textViewDidChange(_ textView: UITextView) {
		switch textView.tag {
		case frontTextView.tag:
			listener?(.front, textView.text)
		case backTextView.tag:
			listener?(.back, textView.text)
		default:
			return
		}
	}
	
	func load(_ side: CardSide) {
		switch side {
		case .front:
			backTextView.isHidden = true
			frontTextView.isHidden = false
		case .back:
			frontTextView.isHidden = true
			backTextView.isHidden = false
		}
		focusTextView(forSide: side)
	}
	
	func swap(completion: ((CardSide) -> Void)?) {
		let halfWidth = view.bounds.width / 2
		if frontTextView.isHidden {
			UIView.animate(withDuration: 0.125, animations: {
				self.backTextView.transform = CGAffineTransform(translationX: halfWidth, y: 0)
				self.backTextView.alpha = 0
			}) {
				guard $0 else { return }
				self.backTextView.isHidden = true
				self.backTextView.transform = .identity
				self.backTextView.alpha = 1
				self.focusTextView(forSide: .front)
				self.frontTextView.transform = CGAffineTransform(translationX: -halfWidth, y: 0)
				self.frontTextView.alpha = 0
				self.frontTextView.isHidden = false
				UIView.animate(withDuration: 0.125, animations: {
					self.frontTextView.transform = .identity
					self.frontTextView.alpha = 1
				}) {
					guard $0 else { return }
					completion?(.front)
				}
			}
		} else {
			UIView.animate(withDuration: 0.125, animations: {
				self.frontTextView.transform = CGAffineTransform(translationX: -halfWidth, y: 0)
				self.frontTextView.alpha = 0
			}) {
				guard $0 else { return }
				self.frontTextView.isHidden = true
				self.frontTextView.transform = .identity
				self.frontTextView.alpha = 1
				self.focusTextView(forSide: .back)
				self.backTextView.transform = CGAffineTransform(translationX: halfWidth, y: 0)
				self.backTextView.alpha = 0
				self.backTextView.isHidden = false
				UIView.animate(withDuration: 0.125, animations: {
					self.backTextView.transform = .identity
					self.backTextView.alpha = 1
				}) {
					guard $0 else { return }
					completion?(.back)
				}
			}
		}
	}
}
