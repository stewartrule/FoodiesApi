import Fluent
import FluentPostgresDriver
import FluentSQL
import Vapor

struct BusinessControllerOld: RouteCollection {
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
                is: .nil || .range(2...25),
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

    struct BusinessAggregate: Content {
        let id: Business.IDValue
        let business: Business
        let reviewCount: Int
        let averageRating: Double
    }

    func boot(routes: RoutesBuilder) throws {
        let group = routes.grouped(.constant(Business.schema))
        group.get(use: index)
    }

    //    func index(req: Request) async throws -> [BusinessAggregate] {
    func index(req: Request) async throws -> [Business] {
        try Filter.validate(query: req)
        let filter = try req.query.decode(Filter.self)
        let postalCode = filter.postalCode
        let distance = filter.distance ?? 10

        //        guard let db = req.db as? SQLDatabase else {
        //            throw Abort(.internalServerError)
        //        }

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

        let foo =
            try await Business
            .query(on: req.db)
            .join(Address.self, on: \Business.$address.$id == \Address.$id)
            .join(
                PostalArea.self,
                on: \Address.$postalArea.$id == \PostalArea.$id
            )
            .with(\.$cuisines)
            .with(\.$businessType)
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
        return foo

        //        let query = db.raw(
        //            """
        //            SELECT
        //                v.*
        //            FROM
        //                (
        //                    SELECT
        //                        businesses.*,
        //                        COALESCE(
        //                            6371 * ACOS(
        //                                COS(RADIANS(\(bind: postalArea.latitude)))
        //                                * COS(RADIANS(addresses.latitude))
        //                                * COS(RADIANS(addresses.longitude) - RADIANS(\(bind: postalArea.longitude)))
        //                                + SIN(RADIANS(\(bind: postalArea.latitude)))
        //                                * SIN(RADIANS(addresses.latitude))
        //                            ),
        //                            0
        //                        ) AS distance
        //                    FROM
        //                        businesses
        //                    INNER JOIN
        //                        addresses ON businesses.address_id = addresses.id
        //                ) v
        //            GROUP BY
        //                v.id, v.name, v.description, v.address_id, v.business_type_id, v.distance
        //            HAVING
        //                v.distance <= \(bind: distance)
        //            ORDER BY
        //                v.distance ASC
        //            """
        //        )
        //
        //        // let bar = Calendar.current.component(.weekday, from: Date())
        //
        //        // Unfortunately we can't load relations on raw queries
        //        // so we have to do a bunch of workarounds :(
        //        let businesses =
        //            try await query
        //            .all(decoding: Business.self)
        //
        //        let businessIds = businesses.compactMap(\.id)
        //
        //        // Gather all related addresses.
        //        let addressIds = businesses.map(\.$address.id)
        //        let addresses =
        //            try await Address
        //            .query(on: req.db)
        //            .filter(\.$id ~~ addressIds)
        //            .all()
        //
        //        // Gather all related business types.
        //        let businessTypeIds = businesses.map(\.$businessType.id)
        //        let businessTypes =
        //            try await BusinessType
        //            .query(on: req.db)
        //            .filter(\.$id ~~ businessTypeIds)
        //            .all()
        //
        //        // Gather all related cuisines.
        //        let businessCuisinePivot =
        //            try await BusinessCuisine
        //            .query(on: req.db)
        //            .filter(\.$business.$id ~~ businessIds)
        //            .all()
        //        let cuisineIds = businessCuisinePivot.map({ $0.$cuisine.id })
        //        let cuisines =
        //            try await Cuisine
        //            .query(on: req.db)
        //            .filter(\.$id ~~ cuisineIds)
        //            .all()
        //
        //        var aggregate: [BusinessAggregate] = []
        //
        //        // Assign relations to businesses.
        //        for business in businesses {
        //            business.$address.value = addresses.first(where: { address in
        //                business.$address.id == address.id
        //            })
        //            business.$businessType.value = businessTypes.first(where: { businessType in
        //                business.$businessType.id == businessType.id
        //            })
        //
        //            let cuisineIds =
        //                businessCuisinePivot
        //                .filter { pivot in
        //                    pivot.$business.id == business.id
        //                }
        //                .compactMap { pivot in
        //                    pivot.$cuisine.id
        //                }
        //
        //            let businessID = try business.requireID()
        //
        //            business.$cuisines.value =
        //                try cuisines
        //                .filter({ cuisineIds.contains(try $0.requireID()) })
        //
        //            let reviewCount =
        //                try await BusinessReview
        //                .query(on: req.db)
        //                .filter(\.$business.$id == businessID)
        //                .count()
        //
        //            let averageRating =
        //                try await BusinessReview
        //                .query(on: req.db)
        //                .filter(\.$business.$id == businessID)
        //                .average(\.$rating) ?? 0
        //
        //            aggregate.append(
        //                BusinessAggregate(
        //                    id: businessID,
        //                    business: business,
        //                    reviewCount: reviewCount,
        //                    averageRating: averageRating
        //                )
        //            )
        //        }
        //
        //        return aggregate
    }
}
