import UIKit

class EmojiGameViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
	@IBOutlet weak var emojiLabel: UILabel!
	@IBOutlet weak var mainLabel: UILabel!
	@IBOutlet weak var blockView: UIView!
	@IBOutlet weak var countTextField: UITextField!
	@IBOutlet weak var countBarView: UIView!
	@IBOutlet weak var difficultyCollectionView: UICollectionView!
	@IBOutlet weak var changeGameStateButton: UIButton!
	
	class Difficulty {
		let count: Int
		let name: String
		let textColor: UIColor
		let backgroundColor: UIColor
		
		init(count: Int, name: String, textColor: UIColor = .white, backgroundColor: UIColor) {
			self.count = count
			self.name = name
			self.textColor = textColor
			self.backgroundColor = backgroundColor
		}
	}
	
	enum GameState {
		case ready
		case timerIsOn
		case timerDidEnd
	}
	
	let EMOJIS = "😀😃😄😁😆😅😂🤣☺️🥰😘😗😇😊☺️🙂🙃😉😌😍😋😛😝🤪😜🤩😎🤓🥳😭😤"
	let DELAY = 20
	let GUESS_COUNT = 5
	let DIFFICULTIES = [
		Difficulty(count: 10, name: "EASY", backgroundColor: #colorLiteral(red: 0.337254902, green: 0.8235294118, blue: 0.2, alpha: 1)),
		Difficulty(count: 15, name: "MEDIUM", backgroundColor: #colorLiteral(red: 0, green: 0.4784313725, blue: 1, alpha: 1)),
		Difficulty(count: 20, name: "HARD", backgroundColor: #colorLiteral(red: 0.8, green: 0.2, blue: 0.2, alpha: 1)),
		Difficulty(count: 30, name: "EXPERT", backgroundColor: #colorLiteral(red: 0.5568627715, green: 0.3529411852, blue: 0.9686274529, alpha: 1)),
		Difficulty(count: -1, name: "SELECT COUNT", textColor: .darkGray, backgroundColor: #colorLiteral(red: 0.9150854945, green: 0.9158141017, blue: 0.9373884797, alpha: 1))
	]
	
	var gameState = GameState.ready
	var currentDifficulty: Difficulty?
	var currentEmojis = [String]()
	var emojisToGuess = [String]()
	var timer: Timer?
	var seconds = 0
	
	override func viewDidLoad() {
		super.viewDidLoad()
		currentDifficulty = DIFFICULTIES.first
		emojiLabel.text = "---"
		setMainLabelTimerText()
	}
	
	@IBAction
	func changeGameState() {
		switch gameState {
		case .ready:
			setEmojiLabel()
			startTimer()
			gameState = .timerIsOn
		case .timerIsOn:
			return
		case .timerDidEnd:
			didGetCountCorrect(currentEmojis.filter { $0 == self.emojisToGuess.first }.count == Int(countTextField.text?.trimAll() ?? "")) {
				self.emojisToGuess.removeFirst()
				self.nextGuess()
			}
		}
	}
	
	func chooseEmojis(_ count: Int) -> [String] {
		currentEmojis = (1...count).compactMap { _ in EMOJIS.randomElement() }.map(String.init)
		return currentEmojis
	}
	
	func setEmojiLabel() {
		emojiLabel.text = chooseEmojis(currentDifficulty?.count ?? 10).joined()
	}
	
	func startTimer() {
		seconds = DELAY
		setMainLabelTimerText()
		blockView.alpha = 0
		blockView.isHidden = false
		UIView.animate(withDuration: 0.15) {
			self.blockView.alpha = 1
		}
		timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
			self.seconds -= 1
			self.setMainLabelTimerText()
			guard self.seconds <= 0 else { return }
			self.timer?.invalidate()
			self.difficultyCollectionView.isHidden = true
			self.changeGameStateButton.setTitle("SUBMIT", for: .normal)
			UIView.animate(withDuration: 0.15, animations: {
				self.blockView.alpha = 0
			}) {
				guard $0 else { return }
				self.blockView.isHidden = true
				self.emojisToGuess = (1...self.currentEmojis.count / 2).compactMap { _ in self.currentEmojis.randomElement() }
				self.gameState = .timerDidEnd
				self.changeGameState()
			}
		}
	}
	
	func setMainLabelTimerText() {
		mainLabel.text = "\(seconds)s left"
	}
	
	func nextGuess() {
		if let emoji = emojisToGuess.first {
			mainLabel.text = "How many \(emoji) were there?"
		} else {
			//$ Show completion
		}
	}
	
	func didGetCountCorrect(_ correct: Bool, completion: @escaping () -> Void) {
		UIView.animate(withDuration: 0.15, animations: {
			self.view.backgroundColor = correct ? #colorLiteral(red: 0.2823529412, green: 0.8, blue: 0.4980392157, alpha: 1) : #colorLiteral(red: 0.8, green: 0.2, blue: 0.2, alpha: 1)
		}) {
			guard $0 else { return }
			UIView.animate(withDuration: 0.15, animations: {
				self.view.backgroundColor = .white
			}) {
				if $0 { completion() }
			}
		}
	}
	
	func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
		return DIFFICULTIES.count
	}
	
	func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
		let _cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath)
		guard let cell = _cell as? EmojiGameDifficultyCollectionViewCell else { return _cell }
		let element = DIFFICULTIES[indexPath.item]
		cell.label.text = element.name
		cell.label.textColor = element.textColor
		cell.backgroundColor = element.backgroundColor
		return cell
	}
}

class EmojiGameDifficultyCollectionViewCell: UICollectionViewCell {
	@IBOutlet weak var label: UILabel!
}
