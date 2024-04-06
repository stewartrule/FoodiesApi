import Fluent
import Vapor

final class Discount: Model, Content {
    static let schema = "discounts"

    @ID(key: .id)
    var id: UUID?

    @Field(key: "name")
    var name: String

    @Field(key: "percentage")
    var percentage: Int

    @Parent(key: "business_id")
    var business: Business

    @Timestamp(key: "online_date", on: .none)
    var onlineDate: Date?

    @Timestamp(key: "offline_date", on: .none)
    var offlineDate: Date?

    init() {}

    init(
        id: UUID? = nil,
        name: String,
        percentage: Int,
        businessID: Business.IDValue,
        onlineDate: Date?,
        offlineDate: Date?
    ) {
        self.id = id
        self.name = name
        self.percentage = percentage
        self.$business.id = businessID
        self.onlineDate = onlineDate
        self.offlineDate = offlineDate
    }
}
