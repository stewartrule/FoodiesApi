import Fluent
import Vapor

extension Request { var orderRepository: OrderRepository { .init(req: self) } }

struct OrderRepository {
    var req: Request

    init(req: Request) { self.req = req }

    func query() -> QueryBuilder<Order> { Order.query(on: req.db) }

    func paginateFor(businessId: Business.IDValue) async throws -> Page<Order> {
        return try await query().filter(\.$business.$id == businessId)
            .with(
                \.$address,
                { address in
                    address.with(
                        \.$postalArea,
                        { postalArea in postalArea.with(\.$city) }
                    )
                }
            )
            .with(\.$customer).with(\.$courier).sort(\.$createdAt)
            .paginate(for: req)
    }

    func findBy(orderId: Order.IDValue) async throws -> Order? {
        return try await query().filter(\.$id == orderId)
            .with(
                \.$address,
                { address in
                    address.with(
                        \.$postalArea,
                        { postalArea in postalArea.with(\.$city) }
                    )
                }
            )
            .with(\.$items, { item in item.with(\.$product) }).with(\.$customer)
            .with(\.$courier).with(\.$chat).first()
    }
}
