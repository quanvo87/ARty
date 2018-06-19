import Alamofire

class LocationDatabase {
    private static let url = "https://arty-backend.herokuapp.com"
    private var isQuerying = false

    static func setUid(_ uid: String, complation: @escaping (Error?) -> Void) {
        let query = "/user/create?uid=\(uid)"

        Alamofire.request(url + query, method: .post).validate().responseString { response in
            switch response.result {
            case .success:
                complation(nil)
            case .failure(let error):
                complation(error)
            }
        }
    }

    static func setLocation(uid: String,
                            latitude: Double,
                            longitude: Double,
                            completion: @escaping (Error?) -> Void) {
        let query = "/user/update?uid=\(uid)&lat=\(latitude)&long=\(longitude)"

        Alamofire.request(url + query, method: .post).validate().responseString { response in
            switch response.result {
            case .success:
                completion(nil)
            case .failure(let error):
                completion(error)
            }
        }
    }

    func nearbyUsers(uid: String,
                     latitude: Double,
                     longitude: Double,
                     querySize: Int = 20,
                     radius: Int = 100,
                     completion: @escaping (Database.Result<[String], Error>) -> Void) {
        guard !isQuerying else {
            return
        }
        isQuerying = true

        // swiftlint:disable line_length
        let query = "/user/getNearby?uid=\(uid)&lat=\(latitude)&long=\(longitude)&querySize=\(querySize)&radius=\(radius)"
        // swiftlint:enable line_length

        Alamofire.request(LocationDatabase.url + query).nearbyUsersResponse { [weak self] response in
            self?.isQuerying = false
            if let error = response.result.error {
                completion(.fail(error))
                return
            }
            guard let nearbyUsers = response.result.value else {
                completion(.fail(ARtyError.invalidDataFromServer(response.result)))
                return
            }
            completion(.success(nearbyUsers.map {
                return $0.uid
            }))
        }
    }
}

extension LocationDatabase {
    struct User: Codable {
        let uid: String
    }
}

private extension DataRequest {
    func decodableResponseSerializer<T: Decodable>() -> DataResponseSerializer<T> {
        return DataResponseSerializer { _, _, data, error in
            if let error = error {
                return .failure(error)
            }
            guard let data = data else {
                return .failure(AFError.responseSerializationFailed(reason: .inputDataNil))
            }
            return Result {
                try JSONDecoder().decode(T.self, from: data)
            }
        }
    }

    func decodableResponse<T: Decodable>(queue: DispatchQueue? = nil,
                                         completionHandler: @escaping (DataResponse<T>) -> Void) -> Self {
        return response(
            queue: queue,
            responseSerializer: decodableResponseSerializer(),
            completionHandler: completionHandler
        )
    }

    @discardableResult
    func nearbyUsersResponse(queue: DispatchQueue? = nil,
                             completionHandler: @escaping (DataResponse<[LocationDatabase.User]>) -> Void) -> Self {
        return decodableResponse(queue: queue, completionHandler: completionHandler)
    }
}
