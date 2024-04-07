import Fluent
import Vapor

final class Chat: Model, Content {
    static let schema = "chats"

    enum Sender: String, Codable { case customer, courier }

    @ID(key: .id) var id: UUID?

    @Timestamp(key: "created_at", on: .create) var createdAt: Date?

    @Timestamp(key: "seen_at", on: .none) var seenAt: Date?

    @Field(key: "message") var message: String

    @Parent(key: "order_id") var order: Order

    @Parent(key: "customer_id") var customer: Customer

    @Parent(key: "courier_id") var courier: Courier

    @Enum(key: "sender") var sender: Sender

    init() {}

    init(
        id: UUID? = nil,
        orderID: Order.IDValue,
        customerID: Customer.IDValue,
        courierID: Courier.IDValue,
        message: String,
        sender: Sender,
        seenAt: Date? = nil
    ) {
        self.id = id
        self.$order.id = orderID
        self.$customer.id = customerID
        self.$courier.id = courierID
        self.message = message
        self.sender = sender
        self.seenAt = seenAt
    }
}
