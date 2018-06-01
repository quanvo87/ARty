import UIKit

class EditAnimationsViewController: UIViewController {
    @IBOutlet weak var animationTypePicker: UISegmentedControl!

    @IBOutlet weak var tableView: UITableView!

    private var arty: ARty?

    private var animations = [String]()

    var delegate: EditAnimationsViewControllerDelegate?

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.title = "Edit Animations"

        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "Close",
            style: .plain,
            target: self,
            action: #selector(close)
        )

        animationTypePicker.addTarget(self, action: #selector(didPickAnimationType), for: .valueChanged)

        tableView.dataSource = self
        tableView.delegate = self
        tableView.tableFooterView = UIView(frame: .zero)
        tableView.reloadData()
    }

    func setARty(_ arty: ARty) {
        self.arty = arty
        animations = try! schema.pickableAnimations(arty.model)
    }
}

extension EditAnimationsViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return animations.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let animation = animations[indexPath.row]

        let cell = UITableViewCell()

        cell.textLabel?.text = animation.animationDisplayName

        let currentAnimation = animationTypePicker.selectedSegmentIndex == 0 ? arty?.passiveAnimation : arty?.pokeAnimation
        if animation == currentAnimation {
            cell.accessoryType = .checkmark
        }

        return cell
    }
}

extension EditAnimationsViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        guard let arty = arty else {
            return
        }

        let animation = animations[indexPath.row]

        switch animationTypePicker.selectedSegmentIndex {
        case 0:
            delegate?.setPassiveAnimation(to: animation, for: arty)
        case 1:
            delegate?.setPokeAnimation(to: animation, for: arty)
        default:
            break
        }

        tableView.reloadData()
    }
}

private extension EditAnimationsViewController {
    @objc func close() {
        dismiss(animated: true)
    }

    @objc func didPickAnimationType() {
        tableView.reloadData()
    }
}
