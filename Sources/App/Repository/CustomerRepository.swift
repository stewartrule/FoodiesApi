import Fluent
import Vapor

extension Request {
    var customerRepository: CustomerRepository { .init(req: self) }
}

struct CustomerRepository {
    var req: Request

    init(req: Request) { self.req = req }

    func query() -> QueryBuilder<Customer> { Customer.query(on: req.db) }

    func getChats(customerID: Customer.IDValue, orderID: Order.IDValue)
        async throws -> Page<Chat>
    {
        try await Chat.query(on: req.db).filter(\.$order.$id == orderID)
            .filter(\.$customer.$id == customerID)
            .sort(\.$createdAt, .descending).paginate(for: req)
    }

    func getOrders(customerID: Customer.IDValue) async throws -> Page<Order> {
        return try await Order.query(on: req.db)
            .filter(\.$customer.$id == customerID).with(\.$address)
            .with(\.$business).with(\.$customer).with(\.$courier)
            .sort(\.$createdAt, .descending).paginate(for: req)
    }

    func getOrder(customerID: Customer.IDValue, orderID: Order.IDValue)
        async throws -> Order?
    {
        try await Order.query(on: req.db).filter(\.$id == orderID)
            .filter(\.$customer.$id == customerID).with(\.$address)
            .with(\.$business).with(\.$customer).with(\.$courier)
            .with(
                \.$items,
                { item in
                    item.with(\.$product) { product in
                        product.with(\.$productType).with(\.$discounts)
                            .with(
                                \.$products,
                                { rel in rel.with(\.$productType) }
                            )
                    }
                }
            )
            .first()
    }

    func find(customerID: Customer.IDValue) async throws -> Customer? {
        return try await query().filter(\.$id == customerID)
            .with(
                \.$addresses,
                { addresses in
                    addresses.with(
                        \.$postalArea,
                        { postalArea in
                            postalArea.with(
                                \.$city,
                                { city in city.with(\.$province) }
                            )
                        }
                    )
                }
            )
            .first()
    }
}
