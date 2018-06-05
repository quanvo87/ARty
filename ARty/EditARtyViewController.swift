import UIKit

protocol EditARtyViewControllerDelegate: class {
    func didChangeARty(to arty: String)
}

class EditARtyViewController: UIViewController {
    private let tableView = UITableView(frame: .zero)

    private let arties = Array(schema.arties.keys)
    
    private weak var delegate: EditARtyViewControllerDelegate?

    init(delegate: EditARtyViewControllerDelegate) {
        super.init(nibName: nil, bundle: nil)

        self.delegate = delegate

        navigationItem.title = "Edit ARty"

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

extension EditARtyViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return arties.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let arty = arties[indexPath.row]
        let cell = UITableViewCell()
        cell.textLabel?.text = arty.capitalized
        return cell
    }
}

extension EditARtyViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let arty = arties[indexPath.row]
        delegate?.didChangeARty(to: arty)
        close()
    }
}

private extension EditARtyViewController {
    @objc func close() {
        dismiss(animated: true)
    }
}
