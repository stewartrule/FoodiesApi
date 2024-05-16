import Fluent
import Vapor

extension Request { var orderRepository: OrderRepository { .init(req: self) } }

struct OrderRepository {
    var req: Request

    init(req: Request) { self.req = req }

    func query() -> QueryBuilder<Order> { Order.query(on: req.db) }

    func queryWithBaseRelations() -> QueryBuilder<Order> {
        return query()
            .with(
                \.$address,
                { address in
                    address.with(
                        \.$postalArea,
                        { postalArea in postalArea.with(\.$city) }
                    )
                }
            )
            .with(
                \.$business,
                { business in
                    business.with(
                        \.$address,
                        { address in
                            address.with(
                                \.$postalArea,
                                { postalArea in postalArea.with(\.$city) }
                            )
                        }
                    )
                }
            )
            .with(
                \.$customer,
                { customer in
                    customer.with(\.$image)
                }
            )
            .with(
                \.$courier,
                { courier in
                    courier.with(\.$image)
                }
            )
            .with(
                \.$items,
                { item in
                    item.with(\.$product) { product in
                        product
                            .with(\.$productType)
                            .with(\.$discounts)
                            .with(\.$image)
                            .with(
                                \.$products,
                                { rel in rel.with(\.$productType) }
                            )
                    }
                }
            )
    }

    func paginateFor(businessID: Business.IDValue) async throws -> Page<Order> {
        return try await queryWithBaseRelations()
            .filter(\.$business.$id == businessID)
            .sort(\.$createdAt, .descending)
            .paginate(for: req)
    }

    func paginateFor(customerID: Customer.IDValue) async throws -> Page<Order> {
        return try await queryWithBaseRelations()
            .filter(\.$customer.$id == customerID)
            .sort(\.$createdAt, .descending)
            .paginate(for: req)
    }

    func getPendingOrdersFor(customerID: Customer.IDValue) async throws
        -> [Order]
    {
        return try await queryWithBaseRelations()
            .filter(\.$customer.$id == customerID)
            .with(\.$chat)
            .group(.or) { group in
                group
                    .filter(\.$preparedAt == nil)
                    .filter(\.$deliveredAt == nil)
                    .filter(\.$sentAt == nil)
            }
            .sort(\.$createdAt, .descending)
            .all()
    }

    func firstBy(customerID: Customer.IDValue, orderID: Order.IDValue)
        async throws -> Order?
    {
        return try await queryWithBaseRelations()
            .filter(\.$customer.$id == customerID)
            .filter(\.$id == orderID)
            .with(\.$chat)
            .with(\.$courier)
            .sort(\.$createdAt, .descending)
            .first()
    }
}
