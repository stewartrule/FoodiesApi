import Fluent
import Vapor

final class CustomerToken: Model, Content {
    static let schema = "customer_tokens"

    @ID(key: .id)
    var id: UUID?

    @Timestamp(key: "created_at", on: .create)
    var createdAt: Date?

    @Field(key: "value")
    var value: String

    @Parent(key: "customer_id")
    var customer: Customer

    init() {}

    init(
        id: UUID? = nil,
        createdAt: Date,
        value: String,
        customerID: Customer.IDValue
    ) {
        self.id = id
        self.value = value
        self.createdAt = createdAt
        self.$customer.id = customerID
    }
}

extension CustomerToken: ModelTokenAuthenticatable {
    static let valueKey = \CustomerToken.$value
    static let userKey = \CustomerToken.$customer

    var isValid: Bool {
        true
    }
}
