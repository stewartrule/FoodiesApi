import Fluent
import Vapor

final class Courier: Model, Content {
    static let schema = "couriers"

    @ID(key: .id)
    var id: UUID?

    @Field(key: "first_name")
    var firstName: String

    @Field(key: "last_name")
    var lastName: String

    @Field(key: "telephone")
    var telephone: String

    init() {}

    init(
        id: UUID? = nil,
        firstName: String,
        lastName: String,
        telephone: String
    ) {
        self.id = id
        self.firstName = firstName
        self.lastName = lastName
        self.telephone = telephone
    }
}
