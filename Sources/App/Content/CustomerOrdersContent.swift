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
        try CustomerOrdersContent(
            id: customer.requireID(),
            firstName: customer.firstName,
            lastName: customer.lastName,
            email: customer.email,
            telephone: customer.telephone,
            addresses: customer.addresses,
            orders: await customer.orders.asyncMap {
                try await OrderContent.from(req: req, order: $0)
            }
        )
    }
}
