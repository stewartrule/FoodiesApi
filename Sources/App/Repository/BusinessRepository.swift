import Fluent
import Vapor

extension Request {
    var businessRepository: BusinessRepository { .init(req: self) }
}

struct BusinessRepository {
    var req: Request

    init(req: Request) { self.req = req }

    func query() -> QueryBuilder<Business> { Business.query(on: req.db) }

    func find(businessID: Business.IDValue) async throws -> Business? {
        return try await query().filter(\.$id == businessID)
            .with(
                \.$address,
                { address in
                    address.with(
                        \.$postalArea,
                        { postalArea in postalArea.with(\.$city) }
                    )
                }
            )
            .with(\.$businessType).with(\.$openingHours).with(\.$cuisines)
            .with(
                \.$products,
                { p1 in
                    p1.with(\.$productType).with(\.$discounts)
                        .with(\.$products, { p2 in p2.with(\.$productType) })
                }
            )
            .first()
    }

    func find(
        near location: Locatable,
        upto distance: Int = 5
    ) async throws -> [Business] {
        let kmInDegree = 111.0
        let offset = 1.0 / (kmInDegree / Double(distance))

        let lat1 = location.latitude - offset
        let lat2 = location.latitude + offset
        let lon1 = location.longitude - offset
        let lon2 = location.longitude + offset

        return try await query()
            .join(Address.self, on: \Business.$address.$id == \Address.$id)
            .join(
                PostalArea.self,
                on: \Address.$postalArea.$id == \PostalArea.$id
            )
            .with(\.$cuisines).with(\.$businessType).with(\.$openingHours)
            .with(\.$address) { address in
                address.with(\.$postalArea) { postalArea in
                    postalArea.with(\.$city)
                }
            }
            .filter(Address.self, \.$latitude > lat1)
            .filter(Address.self, \.$latitude < lat2)
            .filter(Address.self, \.$longitude > lon1)
            .filter(Address.self, \.$longitude < lon2).limit(100).all()
    }
}
