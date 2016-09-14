

import UIKit
import Signals

class DetailViewController: UIViewController {
	
	@IBOutlet weak var nameLabel: UILabel!
	@IBOutlet weak var leadLabel: UILabel!
	@IBOutlet weak var imageView: UIImageView!
	
	weak var imageTask:DownloadTask?
	
	var detailItem: Person? {
		didSet {
			// Update the view
			self.configureView()
		}
	}
	
	override func viewDidLoad() {
		super.viewDidLoad()
		self.configureView()
	}
	
	func configureView() {
		// Update the user interface for the detail item.
		if let detail = self.detailItem {
			nameLabel?.text = "\(detail.firstName) \(detail.lastName)"
			leadLabel?.text = detail.role
			
			if let imageData = detail.profileImageData {
				imageView?.image = UIImage(data: imageData)
			}
			else {
				if imageTask == nil {
					// fetch image
					imageTask = DownloadTask(url: detail.profileImageURL)
					imageTask?.onLoadError.listen(self, callback: { error in
						self.imageView?.image = UIImage(named: "empty")
					})
					imageTask?.start()
				}
			}
		}
	}
}






