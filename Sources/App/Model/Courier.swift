import Fluent
import Vapor

final class Courier: Model, Content {
    static let schema = "couriers"

    @ID(key: .id) var id: UUID?

    @Field(key: "first_name") var firstName: String

    @Field(key: "last_name") var lastName: String

    @Field(key: "telephone") var telephone: String

    @OptionalParent(key: "image_id") var image: Image?

    init() {}

    init(
        id: UUID? = nil,
        firstName: String,
        lastName: String,
        telephone: String,
        imageID: Image.IDValue
    ) {
        self.id = id
        self.firstName = firstName
        self.lastName = lastName
        self.telephone = telephone
        self.$image.id = imageID
    }
}
