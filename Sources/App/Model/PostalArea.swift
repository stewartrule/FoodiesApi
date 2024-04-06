import Fluent
import Vapor

final class PostalArea: Model, Content, Locatable {
    static let schema = "postal_areas"

    @ID(key: .id)
    var id: UUID?

    @Field(key: "postal_code")
    var postalCode: Int

    @Field(key: "latitude")
    var latitude: Double

    @Field(key: "longitude")
    var longitude: Double

    @Parent(key: "city_id")
    var city: City

    init() {}

    init(
        id: UUID? = nil,
        postalCode: Int,
        latitude: Double,
        longitude: Double,
        cityID: City.IDValue
    ) {
        self.id = id
        self.postalCode = postalCode
        self.latitude = latitude
        self.longitude = longitude
        self.$city.id = cityID
    }
}
