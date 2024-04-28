import Fluent
import Vapor

extension Request {
    var profileRepository: ProfileRepository { .init(req: self) }
}

struct ProfileRepository {
    var req: Request

    init(req: Request) { self.req = req }

    func query() -> QueryBuilder<Customer> { Customer.query(on: req.db) }

    func getProfile() async throws -> Customer? {
        // todo: handle actual login
        return try await query().with(\.$image)
            .with(
                \.$addresses,
                { addresses in
                    addresses.with(
                        \.$postalArea,
                        { postalArea in postalArea.with(\.$city) }
                    )
                }
            )
            //            .filter(\.$id == "e02b19ed-8fc8-43c6-8a1f-a407b5c82fdf")
            .sort(\.$createdAt, .ascending).first()
    }

    func getOrders() async throws -> Page<Order>? {
        guard let profile = try await getProfile() else { return nil }
        return try await req.orderRepository.paginateFor(
            customerID: try profile.requireID()
        )
    }

    func getPendingOrders() async throws -> [Order]? {
        guard let profile = try await getProfile() else { return nil }
        return try await req.orderRepository.getPendingOrdersFor(
            customerID: try profile.requireID()
        )
    }

    func getOrder(orderID: UUID) async throws -> Order? {
        guard let profile = try await getProfile() else { return nil }
        guard
            let order = try await req.orderRepository.findBy(
                customerID: try profile.requireID(),
                orderId: orderID
            )
        else { return nil }
        return order
    }
}
