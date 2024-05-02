import Fluent
import Vapor

final class Customer: Model, Content {
    static let schema = "customers"

    @ID(key: .id)
    var id: UUID?

    @Field(key: "first_name")
    var firstName: String

    @Field(key: "last_name")
    var lastName: String

    @Field(key: "email")
    var email: String

    @Field(key: "telephone")
    var telephone: String

    @Timestamp(key: "created_at", on: .create)
    var createdAt: Date?

    @Field(key: "password_hash")
    var passwordHash: String

    @Siblings(through: CustomerAddress.self, from: \.$customer, to: \.$address)
    var addresses: [Address]

    @Children(for: \.$customer)
    var orders: [Order]

    @OptionalParent(key: "image_id")
    var image: Image?

    init() {}

    init(
        id: UUID? = nil,
        firstName: String,
        lastName: String,
        email: String,
        telephone: String,
        passwordHash: String,
        imageID: Image.IDValue
    ) {
        self.id = id
        self.firstName = firstName
        self.lastName = lastName
        self.email = email
        self.telephone = telephone
        self.passwordHash = passwordHash
        self.$image.id = imageID
    }
}

extension Customer {
    func generateToken() throws -> CustomerToken {
        try .init(
            createdAt: Date(),
            value: [UInt8].random(count: 16).base64,
            customerID: self.requireID()
        )
    }
}

extension Customer: ModelAuthenticatable {
    static let usernameKey = \Customer.$email
    static let passwordHashKey = \Customer.$passwordHash

    func verify(password: String) throws -> Bool {
        try Bcrypt.verify(password, created: self.passwordHash)
    }
}
