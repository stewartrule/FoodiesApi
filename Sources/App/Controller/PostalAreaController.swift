import Fluent
import Vapor

struct PostalAreaController: RouteCollection {
    struct Filter: Content, Validatable {
        var postalCode: Int

        static func validations(_ validations: inout Validations) {
            validations.add(
                "postalCode",
                as: Int.self,
                is: .range(1000...9999),
                required: true
            )
        }
    }

    func boot(routes: RoutesBuilder) throws {
        let group = routes.grouped(.constant(PostalArea.schema))
        group.get(use: index)
    }

    func index(req: Request) async throws -> [PostalArea] {
        try Filter.validate(query: req)
        let filter = try req.query.decode(Filter.self)
        let postalCode = filter.postalCode

        return try await PostalArea.query(on: req.db)
            .filter(\.$postalCode == postalCode)
            .with(\.$city)
            .sort(\.$postalCode)
            .limit(10)
            .all()
    }
}
