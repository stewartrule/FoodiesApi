import Vapor

struct CustomerOrdersContent: Content {
    let id: UUID
    let firstName: String
    let lastName: String
    let email: String
    let telephone: String
    let addresses: [Address]
    let orders: [OrderContent]

    static func from(req: Request, customer: Customer) async throws -> Self {
        CustomerOrdersContent(
            id: try customer.requireID(),
            firstName: customer.firstName,
            lastName: customer.lastName,
            email: customer.email,
            telephone: customer.telephone,
            addresses: customer.addresses,
            orders: try await customer.orders.asyncMap {
                try await OrderContent.from(req: req, order: $0)
            }
        )
    }
}
