import Fluent
import Vapor

extension Request {
    var profileRepository: ProfileRepository { .init(req: self) }
}

struct ProfileRepository {
    var req: Request

    init(req: Request) { self.req = req }

    func query() -> QueryBuilder<Customer> { Customer.query(on: req.db) }

    func getProfile(for customer: Customer) async throws -> Customer? {
        return try await query()
            .with(\.$image)
            .with(
                \.$addresses,
                { addresses in
                    addresses.with(
                        \.$postalArea,
                        { postalArea in postalArea.with(\.$city) }
                    )
                }
            )
            .filter(\.$id == customer.requireID())
            .first()
    }

    func getOrders(for profile: Customer) async throws -> Page<Order>? {
        return try await req.orderRepository.paginateFor(
            customerID: try profile.requireID()
        )
    }

    func getPendingOrders(for profile: Customer) async throws -> [Order]? {
        return try await req.orderRepository.getPendingOrdersFor(
            customerID: try profile.requireID()
        )
    }

    func getOrder(for profile: Customer, orderID: UUID) async throws -> Order? {
        guard
            let order = try await req.orderRepository.firstBy(
                customerID: try profile.requireID(),
                orderID: orderID
            )
        else { return nil }
        return order
    }
}
