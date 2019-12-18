import SwiftUI

struct ImagePicker: UIViewControllerRepresentable {
	typealias Source = UIImagePickerController.SourceType
	
	final class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
		@Binding var isShowing: Bool
		@Binding var image: UIImage?
		
		init(isShowing: Binding<Bool>, image: Binding<UIImage?>) {
			_isShowing = isShowing
			_image = image
		}
		
		func imagePickerController(
			_ picker: UIImagePickerController,
			didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
		) {
			guard let image = info[.originalImage] as? UIImage else { return }
			self.image = image
			isShowing = false
		}
		
		func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
			isShowing = false
		}
	}
	
	@Binding var isShowing: Bool
	@Binding var image: UIImage?
	
	let source: Source
	
	init(
		isShowing: Binding<Bool>,
		image: Binding<UIImage?>,
		source: Source = .photoLibrary
	) {
		_isShowing = isShowing
		_image = image
		self.source = source
	}
	
	func makeCoordinator() -> Coordinator {
		.init(isShowing: $isShowing, image: $image)
	}
	
	func makeUIViewController(context: Context) -> UIImagePickerController {
		let picker = UIImagePickerController()
		picker.delegate = context.coordinator
		picker.sourceType = source
		return picker
	}
	
	func updateUIViewController(_ picker: UIImagePickerController, context: Context) {}
}

#if DEBUG
struct ImagePicker_Previews: PreviewProvider {
	static var previews: some View {
		ImagePicker(isShowing: .constant(true), image: .constant(nil))
	}
}
#endif
