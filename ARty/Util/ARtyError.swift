enum ARtyError: Error {
    case invalidDataFromServer(Any?)
    case invalidModelName(String)
    case invalidAnimationName(String)
    case animationIdentifierNotFound(String)
    case resourceNotFound(String)
}
