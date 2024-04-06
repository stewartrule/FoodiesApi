import Fluent
import Vapor

final class Address: Model, Content, Locatable {
    static let schema = "addresses"

    @ID(key: .id)
    var id: UUID?

    @Field(key: "street")
    var street: String

    @Field(key: "postal_code_suffix")
    var postalCodeSuffix: String

    @Field(key: "house_number")
    var houseNumber: Int

    @Field(key: "latitude")
    var latitude: Double

    @Field(key: "longitude")
    var longitude: Double

    @Parent(key: "postal_area_id")
    var postalArea: PostalArea

    init() {}

    init(
        id: UUID? = nil,
        street: String,
        postalCodeSuffix: String,
        houseNumber: Int,
        latitude: Double,
        longitude: Double,
        postalAreaID: PostalArea.IDValue
    ) {
        self.id = id
        self.street = street
        self.postalCodeSuffix = postalCodeSuffix
        self.houseNumber = houseNumber
        self.latitude = latitude
        self.longitude = longitude
        self.$postalArea.id = postalAreaID
    }
}
