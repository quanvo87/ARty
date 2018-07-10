import ARKit

class StatusViewController: UIViewController {
    @IBOutlet weak var spinner: UIActivityIndicatorView!
    @IBOutlet weak var statusLabel: UILabel!

    private var trackingState = ARCamera.TrackingState.notAvailable
    private var waitingOnLocationUpdates = true

    func update(_ status: Status) {
        switch status {
        case .trackingState(let trackingState):
            self.trackingState = trackingState
            if !(trackingState == .normal) {
                statusLabel.text = "Hold camera steady in well-lit area..."
            }
        case .waitingOnLocationUpdates(let waitingOnLocationUpdates):
            self.waitingOnLocationUpdates = waitingOnLocationUpdates
            if waitingOnLocationUpdates {
                statusLabel.text = "Augmenting reality...hold camera steady..."
            }
        }
        render()
    }
}

extension StatusViewController {
    enum Status {
        case trackingState(ARCamera.TrackingState)
        case waitingOnLocationUpdates(Bool)
    }
}

private extension StatusViewController {
    func render() {
        if trackingState == .normal && !waitingOnLocationUpdates {
            spinner.isHidden = true
            statusLabel.isHidden = true
        } else {
            spinner.isHidden = false
            statusLabel.isHidden = false
        }
    }
}
