import Fluent
import Vapor

final class Business: Model, Content {
    static let schema = "businesses"

    @ID(key: .id) var id: UUID?

    @Field(key: "name") var name: String

    @Field(key: "description") var description: String

    @Field(key: "delivery_charge") var deliveryCharge: Int

    @Field(key: "minimum_order_amount") var minimumOrderAmount: Int

    @Siblings(through: BusinessCuisine.self, from: \.$business, to: \.$cuisine)
    var cuisines: [Cuisine]

    @Parent(key: "address_id") var address: Address

    @Parent(key: "business_type_id") var businessType: BusinessType

    @Parent(key: "image_id") var image: Image

    @Children(for: \.$business) var products: [Product]

    @Children(for: \.$business) var openingHours: [OpeningHours]

    @Children(for: \.$business) var productTypes: [ProductType]

    init() {}

    init(
        id: UUID? = nil,
        name: String,
        description: String,
        deliveryCharge: Int,
        minimumOrderAmount: Int,
        addressID: Address.IDValue,
        businessTypeID: BusinessType.IDValue,
        imageID: Image.IDValue
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.deliveryCharge = deliveryCharge
        self.minimumOrderAmount = minimumOrderAmount
        self.$address.id = addressID
        self.$businessType.id = businessTypeID
        self.$image.id = imageID
    }

    func isOpenAt(date: Date) -> Bool {
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: date)

        return openingHours.contains { today in
            if today.weekday != weekday { return false }

            if today.isClosed { return false }

            let hour = calendar.component(.hour, from: date)
            let minute = calendar.component(.minute, from: date)
            let minutes = 60 * hour + minute
            return minutes >= today.startTime && minutes < today.endTime
        }
    }
}
