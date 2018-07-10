import UIKit

class StatusViewController: UIViewController {
    @IBOutlet weak var spinner: UIActivityIndicatorView!
    @IBOutlet weak var statusLabel: UILabel!

    func hide() {
        spinner.isHidden = true
        statusLabel.isHidden = true
    }

    func show() {
        spinner.isHidden = false
        statusLabel.isHidden = false
    }
}
