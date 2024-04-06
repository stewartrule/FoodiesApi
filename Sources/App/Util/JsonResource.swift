import Vapor

extension Task where Success == Never, Failure == Never {
    static func sleep(seconds: Double) async throws {
        let duration = UInt64(seconds * 1_000_000_000)
        try await Task.sleep(nanoseconds: duration)
    }
}

struct SeedCommand: AsyncCommand {
    struct Signature: CommandSignature {}

    var help: String {
        "Seed database with mock data"
    }

    func run(using context: CommandContext, signature: Signature) async throws {
        let progressBar = context.console.progressBar(title: "cuisines")
        let width = 400
        let items = Array(1...width)
        let f = 1.0 / Double(width)
        progressBar.start()
        for i in items {
            progressBar.activity.currentProgress = f * Double(i)
            try await Task.sleep(seconds: 0.01)
        }
        progressBar.succeed()
    }
}

class JsonResource {
    enum ProvinceName: String, Codable {
        case drenthe = "Drenthe"
        case flevoland = "Flevoland"
        case friesland = "Friesland"
        case gelderland = "Gelderland"
        case groningen = "Groningen"
        case limburg = "Limburg"
        case noordBrabant = "Noord-Brabant"
        case noordHolland = "Noord-Holland"
        case overijssel = "Overijssel"
        case utrecht = "Utrecht"
        case zeeland = "Zeeland"
        case zuidHolland = "Zuid-Holland"
    }

    struct PostalCode: Codable {
        let postalCode: Int
        let latitude, longitude: Double
        let city, municipality: String
        let province: ProvinceName

        enum CodingKeys: String, CodingKey {
            case postalCode = "postal_code"
            case latitude, longitude, city, municipality, province
        }
    }

    struct RestaurantPhoto: Codable {
        let original_id: Int
        let alt: String
        let src: String
        let avg_color: String
        let cuisine: String
    }

    struct DishPhoto: Codable {
        let original_id: Int
        let alt: String
        let src: String
        let avg_color: String
        let cuisine: String
        let dishtype: String
    }

    private let app: Application
    private let fileManager: FileManager

    init(app: Application, fileManager: FileManager) {
        self.app = app
        self.fileManager = fileManager
    }

    func getPostalCode() throws -> [PostalCode] {
        try load("postalCodes")
    }

    func getRestaurants() throws -> [RestaurantPhoto] {
        try load("restaurants")
    }

    func getDishes() throws -> [DishPhoto] {
        try load("dishes")
    }

    private func load<T: Codable>(_ json: String) throws -> T {
        let path = "\(app.directory.resourcesDirectory)\(json).json"
        guard fileManager.fileExists(atPath: path) else {
            fatalError("\(path) does not exist")
        }
        guard let jsonData = fileManager.contents(atPath: path) else {
            fatalError("\(path) could not be read")
        }
        return try JSONDecoder().decode(T.self, from: jsonData)
    }
}
