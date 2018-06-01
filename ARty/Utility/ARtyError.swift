enum ARtyError: Error {
    case animationIdentifierNotFound(String)
    case invalidAnimationName(String)
    case invalidModelName(String)
    case resourceNotFound(String)
    case invalidDataFromServer([String: Any]?)
}
