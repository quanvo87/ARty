enum ARtyError: Error {
    case invalidDataFromServer(Any?)
    case animationIdentifierNotFound(String)
    case invalidAnimationName(String)
    case invalidModelName(String)
    case resourceNotFound(String)
}
