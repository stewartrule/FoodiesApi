import Fluent
import Vapor

final class Customer: Model, Content {
    static let schema = "customers"

    @ID(key: .id) var id: UUID?

    @Field(key: "first_name") var firstName: String

    @Field(key: "last_name") var lastName: String

    @Field(key: "email") var email: String

    @Field(key: "telephone") var telephone: String

    @Timestamp(key: "created_at", on: .create) var createdAt: Date?

    @Siblings(through: CustomerAddress.self, from: \.$customer, to: \.$address)
    var addresses: [Address]

    @Children(for: \.$customer) var orders: [Order]

    @OptionalParent(key: "image_id") var image: Image?

    init() {}

    init(
        id: UUID? = nil,
        firstName: String,
        lastName: String,
        email: String,
        telephone: String,
        imageID: Image.IDValue
    ) {
        self.id = id
        self.firstName = firstName
        self.lastName = lastName
        self.email = email
        self.telephone = telephone
        self.$image.id = imageID
    }
}
