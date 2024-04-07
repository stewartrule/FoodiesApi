import Fluent
import Vapor

final class Province: Model, Content {
    static let schema = "provinces"

    @ID(key: .id) var id: UUID?

    @Field(key: "name") var name: String

    init() {}

    init(id: UUID? = nil, name: String) {
        self.id = id
        self.name = name
    }
}
