import UIKit

protocol EditAnimationsViewControllerDelegate: class {
    func editAnimationsViewController(_ controller: EditAnimationsViewController,
                                      setPassiveAnimationTo animation: String,
                                      for arty: ARty)
    func editAnimationsViewController(_ controller: EditAnimationsViewController,
                                      setPokeAnimationTo animation: String,
                                      for arty: ARty)
}

// todo: make poke the first segmented control
class EditAnimationsViewController: UIViewController {
    @IBOutlet weak var animationTypePicker: UISegmentedControl!
    @IBOutlet weak var tableView: UITableView!
    private var arty: ARty?
    private var animations = [String]()
    private weak var delegate: EditAnimationsViewControllerDelegate?

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

    static func make(arty: ARty, delegate: EditAnimationsViewControllerDelegate) -> EditAnimationsViewController {
        guard let viewController = UIStoryboard(
            name: "Main",
            bundle: nil).instantiateViewController(
                withIdentifier: String(describing: EditAnimationsViewController.self)
            ) as? EditAnimationsViewController else {
                return EditAnimationsViewController()
        }
        viewController.arty = arty
        viewController.animations = arty.pickableAnimationNames.sorted()
        viewController.delegate = delegate
        return viewController
    }
}

extension EditAnimationsViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return animations.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let animation = animations[indexPath.row]

        let cell = UITableViewCell()
        cell.selectionStyle = .none
        cell.textLabel?.text = animation.animationDisplayName

        let currentAnimation = animationTypePicker.selectedSegmentIndex == 0 ?
            arty?.passiveAnimation :
            arty?.pokeAnimation
        if animation == currentAnimation {
            cell.accessoryType = .checkmark
        }

        return cell
    }
}

extension EditAnimationsViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let arty = arty else {
            return
        }

        let animation = animations[indexPath.row]

        switch animationTypePicker.selectedSegmentIndex {
        case 0:
            delegate?.editAnimationsViewController(self, setPassiveAnimationTo: animation, for: arty)
        case 1:
            delegate?.editAnimationsViewController(self, setPokeAnimationTo: animation, for: arty)
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

private extension String {
    var animationDisplayName: String {
        if let index = self.range(of: "_")?.upperBound {
            return String(self.suffix(from: index)).capitalized.replacingOccurrences(of: "_", with: " ")
        } else {
            return self
        }
    }
}
