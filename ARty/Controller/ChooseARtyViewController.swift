import UIKit

protocol ChooseARtyViewControllerDelegate: class {
    func chooseARtyViewController(_ controller: ChooseARtyViewController, didChooseARty model: String)
}

class ChooseARtyViewController: UIViewController {
    private let tableView = UITableView(frame: .zero)
    private let arties = Array(schema.arties.keys).sorted()
    private weak var delegate: ChooseARtyViewControllerDelegate?

    init(delegate: ChooseARtyViewControllerDelegate) {
        super.init(nibName: nil, bundle: nil)

        self.delegate = delegate

        navigationItem.title = "Choose ARty"
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "Close",
            style: .plain,
            target: self,
            action: #selector(close)
        )

        tableView.frame = CGRect(x: 0, y: 0, width: view.frame.width, height: view.frame.height)
        tableView.tableFooterView = UIView(frame: .zero)
        tableView.dataSource = self
        tableView.delegate = self

        view.addSubview(tableView)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension ChooseARtyViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return arties.count
    }

    // todo: add selection indicator
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let arty = arties[indexPath.row]
        let cell = UITableViewCell()
        cell.textLabel?.text = arty.capitalized
        return cell
    }
}

extension ChooseARtyViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let arty = arties[indexPath.row]
        delegate?.chooseARtyViewController(self, didChooseARty: arty)
        close()
    }
}

private extension ChooseARtyViewController {
    @objc func close() {
        dismiss(animated: true)
    }
}
