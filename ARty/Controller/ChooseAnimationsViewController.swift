import UIKit

class ChooseAnimationsViewController: UIViewController {
    @IBOutlet weak var animationTypePicker: UISegmentedControl!
    @IBOutlet weak var tableView: UITableView!
    private var arty: ARty?
    private var animations = [String]()

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.title = "Choose Animations"
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "Close",
            style: .plain,
            target: self,
            action: #selector(close)
        )

        animationTypePicker.addTarget(self, action: #selector(didSelectAnimationType), for: .valueChanged)

        tableView.dataSource = self
        tableView.delegate = self
        tableView.tableFooterView = UIView(frame: .zero)
        tableView.reloadData()
    }

    static func make(arty: ARty) -> ChooseAnimationsViewController {
        guard let controller = UIStoryboard(
            name: "Main",
            bundle: nil).instantiateViewController(
                withIdentifier: String(describing: ChooseAnimationsViewController.self)
            ) as? ChooseAnimationsViewController else {
                return ChooseAnimationsViewController()
        }
        controller.arty = arty
        controller.animations = arty.pickableAnimationNames.sorted()
        return controller
    }
}

extension ChooseAnimationsViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return animations.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let animation = animations[indexPath.row]

        let cell = UITableViewCell()
        cell.selectionStyle = .none
        cell.textLabel?.text = animation.animationDisplayName

        let currentAnimation = animationTypePicker.selectedSegmentIndex == 0 ?
            arty?.pokeAnimation :
            arty?.passiveAnimation

        if animation == currentAnimation {
            cell.accessoryType = .checkmark
        }

        return cell
    }
}

extension ChooseAnimationsViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let arty = arty else {
            return
        }

        let animation = animations[indexPath.row]

        switch animationTypePicker.selectedSegmentIndex {
        case 0:
            try? arty.setPokeAnimation(animation)
            Database.updatePokeAnimation(to: animation, for: arty) { _ in }
        case 1:
            try? arty.setPassiveAnimation(animation)
            Database.updatePassiveAnimation(to: animation, for: arty) { _ in }
        default:
            break
        }

        tableView.reloadData()
    }
}

private extension ChooseAnimationsViewController {
    @objc func close() {
        dismiss(animated: true)
    }

    @objc func didSelectAnimationType() {
        tableView.reloadData()
    }
}

private extension String {
    var animationDisplayName: String {
        if let index = self.range(of: "_")?.upperBound {
            return String(self.suffix(from: index)).capitalized.replacingOccurrences(of: "_", with: " ")
        } else {
            return self
        }
    }
}
