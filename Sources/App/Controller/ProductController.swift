import Fluent
import Vapor

struct ProductController: RouteCollection {
    struct Filter: Content, Validatable {
        var businessId: UUID

        static func validations(_ validations: inout Validations) {
            validations.add("businessId", as: UUID.self, required: true)
        }
    }

    func boot(routes: RoutesBuilder) throws {
        let group = routes.grouped(.constant(Product.schema))
        group.get(use: index)
    }

    func index(req: Request) async throws -> Business {
        try Filter.validate(query: req)
        let filter = try req.query.decode(Filter.self)
        let businessId = filter.businessId

        guard
            let business = try await Business.query(on: req.db)
                .filter(\.$id == businessId)
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
                .with(\.$businessType)
                .with(\.$cuisines)
                .with(
                    \.$products,
                    { p1 in
                        p1
                            .with(\.$productType)
                            .with(\.$discounts)
                            .with(
                                \.$products,
                                { p2 in
                                    p2
                                        .with(\.$productType)
                                }
                            )
                    }
                )
                .first()
        else {
            throw Abort(.notFound)
        }

        return business
    }
}
