import UIKit
import FirebaseAuth
import FacebookLogin

class LoginViewController: UIViewController {
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: true)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: true)
    }

    @IBAction func didTapSignUpButton(_ sender: Any) {
        guard let email = emailTextField.text, let password = passwordTextField.text else {
            return
        }
        Auth.auth().createUser(withEmail: email, password: password) { [weak self] _, error in
            if let error = error {
                print(error)
                return
            }
            self?.dismiss(animated: true)
        }
    }

    @IBAction func didTapLogInButton(_ sender: Any) {
        guard let email = emailTextField.text, let password = passwordTextField.text else {
            return
        }
        Auth.auth().signIn(withEmail: email, password: password) { [weak self] _, error in
            if let error = error {
                print(error)
                return
            }
            self?.dismiss(animated: true)
        }
    }

    @IBAction func didTapFacebookLoginButton(_ sender: Any) {
        LoginManager().logIn(readPermissions: [.publicProfile]) { [weak self] result in
            switch result {
            case .success(_, _, let token):
                let credential = FacebookAuthProvider.credential(withAccessToken: token.authenticationToken)
                Auth.auth().signInAndRetrieveData(with: credential) { _, error in
                    if let error = error {
                        print(error)
                    } else {
                        self?.dismiss(animated: true)
                    }
                }
            case .failed(let error):
                print(error)
            case .cancelled:
                break
            }
        }
    }
}
