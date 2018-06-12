import UIKit

class ChooseEmotesViewController: UIViewController {
    @IBOutlet weak var emoteTypePicker: UISegmentedControl!
    @IBOutlet weak var tableView: UITableView!
    private var arty: ARty?
    private var emotes = [String]()

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.title = "Choose Emotes"
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "Close",
            style: .plain,
            target: self,
            action: #selector(close)
        )

        emoteTypePicker.addTarget(self, action: #selector(didPickEmoteType), for: .valueChanged)

        tableView.dataSource = self
        tableView.delegate = self
        tableView.tableFooterView = UIView(frame: .zero)
        tableView.reloadData()
    }

    static func make(arty: ARty) -> ChooseEmotesViewController {
        guard let controller = UIStoryboard(
            name: "Main",
            bundle: nil).instantiateViewController(
                withIdentifier: String(describing: ChooseEmotesViewController.self)
            ) as? ChooseEmotesViewController else {
                return ChooseEmotesViewController()
        }
        controller.arty = arty
        controller.emotes = arty.emotes.sorted()
        return controller
    }
}

extension ChooseEmotesViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return emotes.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let emote = emotes[indexPath.row]

        let cell = UITableViewCell()
        cell.selectionStyle = .none
        cell.textLabel?.text = emote.emoteDisplayName

        let currentEmote = emoteTypePicker.selectedSegmentIndex == 0 ?
            arty?.pokeEmote :
            arty?.passiveEmote
        cell.accessoryType = emote == currentEmote ? .checkmark : .none

        return cell
    }
}

extension ChooseEmotesViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let arty = arty else {
            return
        }

        let emote = emotes[indexPath.row]

        switch emoteTypePicker.selectedSegmentIndex {
        case 0:
            try? arty.setPokeEmote(to: emote)
            Database.updatePokeEmote(to: emote, for: arty) { error in
                if let error = error {
                    print(error)
                }
            }
        case 1:
            try? arty.setPassiveEmote(to: emote)
            Database.updatePassiveEmote(to: emote, for: arty) { error in
                if let error = error {
                    print(error)
                }
            }
        default:
            break
        }

        tableView.reloadData()
    }
}

private extension ChooseEmotesViewController {
    @objc func close() {
        dismiss(animated: true)
    }

    @objc func didPickEmoteType() {
        tableView.reloadData()
    }
}

private extension String {
    var emoteDisplayName: String {
        if let index = self.range(of: "_")?.upperBound {
            return String(self.suffix(from: index)).replacingOccurrences(of: "_", with: " ").capitalized
        } else {
            return self
        }
    }
}
