import Fluent
import Vapor

final class Order: Model, Content {
    static let schema = "orders"

    @ID(key: .id) var id: UUID?

    @Timestamp(key: "created_at", on: .create) var createdAt: Date?

    @Timestamp(key: "prepared_at", on: .none) var preparedAt: Date?

    @Timestamp(key: "sent_at", on: .none) var sentAt: Date?

    @Timestamp(key: "delivered_at", on: .none) var deliveredAt: Date?

    @OptionalParent(key: "courier_id") var courier: Courier?

    @Parent(key: "customer_id") var customer: Customer

    @Parent(key: "business_id") var business: Business

    @Parent(key: "address_id") var address: Address

    @Children(for: \.$order) var chat: [Chat]

    @Children(for: \.$order) var items: [ProductOrder]

    init() {}

    init(
        id: UUID? = nil,
        customerID: Customer.IDValue,
        businessID: Business.IDValue,
        addressID: Address.IDValue
    ) {
        self.id = id
        self.$customer.id = customerID
        self.$business.id = businessID
        self.$address.id = addressID
    }
}
