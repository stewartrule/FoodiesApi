import Fluent
import Vapor

final class CustomerAddress: Model, Content {
    static let schema = "customer_address"

    @ID(key: .id) var id: UUID?

    @Parent(key: "customer_id") var customer: Customer

    @Parent(key: "address_id") var address: Address

    init() {}

    init(
        id: UUID? = nil,
        customerID: Customer.IDValue,
        addressID: Address.IDValue
    ) {
        self.id = id
        self.$customer.id = customerID
        self.$address.id = addressID
    }
}
