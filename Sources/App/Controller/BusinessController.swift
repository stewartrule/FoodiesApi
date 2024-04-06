import Fluent
import FluentPostgresDriver
import FluentSQL
import Vapor

struct BusinessController: RouteCollection {
    struct Filter: Content, Validatable {
        var postalCode: Int
        var distance: Int? = 10
        var limit: Int? = 100
        var offset: Int? = 0

        static func validations(_ validations: inout Validations) {
            validations.add(
                "postalCode",
                as: Int.self,
                is: .range(1000...9999),
                required: true
            )
            validations.add(
                "distance",
                as: Int?.self,
                is: .nil || .range(2...20),
                required: false
            )
            validations.add(
                "limit",
                as: Int?.self,
                is: .nil || .range(1...100),
                required: false
            )
            validations.add(
                "offset",
                as: Int?.self,
                is: .nil || .range(1...100),
                required: false
            )
        }
    }

    struct PublicBusiness: Content {
        let id: Business.IDValue
        let business: Business
        let isOpen: Bool
        let distance: Double
        let reviewCount: Int
        let averageRating: Double
    }

    func boot(routes: RoutesBuilder) throws {
        let group = routes.grouped(.constant(Business.schema))
        group.get(use: index)
    }

    func index(req: Request) async throws -> [PublicBusiness] {
        try Filter.validate(query: req)
        let filter = try req.query.decode(Filter.self)
        let postalCode = filter.postalCode
        let distance = filter.distance ?? 10

        guard
            let postalArea =
                try await PostalArea
                .query(on: req.db)
                .filter(\.$postalCode == postalCode)
                .first()
        else {
            throw Abort(.notFound)
        }

        let kmInDegree = 110.0
        let offset = 1.0 / (kmInDegree / Double(distance))

        let lat1 = postalArea.latitude - offset
        let lat2 = postalArea.latitude + offset
        let lon1 = postalArea.longitude - offset
        let lon2 = postalArea.longitude + offset

        let businesses =
            try await Business
            .query(on: req.db)
            .join(Address.self, on: \Business.$address.$id == \Address.$id)
            .join(
                PostalArea.self,
                on: \Address.$postalArea.$id == \PostalArea.$id
            )
            .with(\.$cuisines)
            .with(\.$businessType)
            .with(\.$openingHours)
            .with(\.$address) { address in
                address.with(\.$postalArea) { postalArea in
                    postalArea.with(\.$city)
                }
            }
            .filter(Address.self, \.$latitude > lat1)
            .filter(Address.self, \.$latitude < lat2)
            .filter(Address.self, \.$longitude > lon1)
            .filter(Address.self, \.$longitude < lon2)
            .limit(100)
            .all()

        let now = Date()
        var aggregates: [PublicBusiness] = []
        for business in businesses {
            let businessID = try business.requireID()
            let isOpen = business.isOpenAt(date: now)
            let distance = business.address.getDistanceTo(postalArea)
            let reviewCount =
                try await BusinessReview
                .query(on: req.db)
                .filter(\.$business.$id == businessID)
                .count()
            let averageRating =
                try await BusinessReview
                .query(on: req.db)
                .filter(\.$business.$id == businessID)
                .average(\.$rating) ?? 0

            aggregates.append(
                PublicBusiness(
                    id: businessID,
                    business: business,
                    isOpen: isOpen,
                    distance: distance,
                    reviewCount: reviewCount,
                    averageRating: averageRating
                )
            )
        }

        return aggregates.sorted { lhs, rhs in
            lhs.distance < rhs.distance
        }
    }
}
