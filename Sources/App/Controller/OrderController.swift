import Fluent
import Vapor

struct OrderController: RouteCollection {
    struct Filter: Content, Validatable {
        var businessId: UUID

        static func validations(_ validations: inout Validations) {
            validations.add("businessId", as: UUID.self, required: true)
        }
    }

    func boot(routes: RoutesBuilder) throws {
        let group = routes.grouped(.constant(Order.schema))
        group.get(use: index)
        group.group(":orderId") { order in
            order.get(use: detail)
        }
    }

    func detail(req: Request) async throws -> Order {
        guard let orderId = req.parameters.get("orderId", as: UUID.self) else {
            throw Abort(.badRequest)
        }

        guard
            let order =
                try await Order.query(on: req.db)
                .filter(\.$id == orderId)
                .with(
                    \.$address,
                    { address in
                        address.with(
                            \.$postalArea,
                            { postalArea in
                                postalArea.with(\.$city)
                            }
                        )
                    }
                )
                .with(
                    \.$items,
                    { item in
                        item.with(\.$product)
                    }
                )
                .with(\.$customer)
                .with(\.$courier)
                .with(\.$chat)
                .first()
        else {
            throw Abort(.notFound)
        }

        return order
    }

    func index(req: Request) async throws -> Page<Order> {
        try Filter.validate(query: req)
        let filter = try req.query.decode(Filter.self)
        let businessId = filter.businessId
        let paginator = try await Order.query(on: req.db)
            .filter(\.$business.$id == businessId)
            .with(
                \.$address,
                { address in
                    address.with(
                        \.$postalArea,
                        { postalArea in
                            postalArea.with(\.$city)
                        }
                    )
                }
            )
            .with(\.$customer)
            .with(\.$courier)
            .sort(\.$createdAt)
            .paginate(for: req)

        return paginator
    }
}
