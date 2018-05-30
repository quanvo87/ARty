//
//  EditARtyTableViewController.swift
//  ARty
//
//  Created by Quan Vo on 5/30/18.
//  Copyright © 2018 Quan Vo. All rights reserved.
//

import UIKit

class EditARtyViewController: UIViewController {
    private let tableView = UITableView(frame: .zero, style: .grouped)
    private let arties: [ARty.ModelName] = [.elvira, .mutant]
    private weak var delegate: EditARtyViewControllerDelegate?

    init(delegate: EditARtyViewControllerDelegate) {
        super.init(nibName: nil, bundle: nil)

        self.delegate = delegate

        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "Close",
            style: .plain,
            target: self,
            action: #selector(close)
        )
        navigationItem.title = "Edit ARty"

        tableView.frame = CGRect(x: 0, y: 0, width: view.frame.width, height: view.frame.height)
        tableView.sectionHeaderHeight = 0
        tableView.dataSource = self
        tableView.delegate = self

        view.addSubview(tableView)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

private extension EditARtyViewController {
    @objc func close() {
        dismiss(animated: true)
    }
}

extension EditARtyViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return arties.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let arty = arties[indexPath.row]
        let cell = UITableViewCell()
        cell.textLabel?.text = arty.rawValue
        return cell
    }
}

extension EditARtyViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return .leastNormalMagnitude
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let arty = arties[indexPath.row]
        delegate?.didSelectARrty(arty)
        close()
    }
}
