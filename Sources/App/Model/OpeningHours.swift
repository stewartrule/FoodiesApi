import Fluent
import Vapor

final class OpeningHours: Model, Content {
    static let schema = "opening_hours"

    @ID(key: .id)
    var id: UUID?

    @Field(key: "weekday")
    var weekday: Int

    @Field(key: "start_time")
    var startTime: Int

    @Field(key: "end_time")
    var endTime: Int

    @Field(key: "is_closed")
    var isClosed: Bool

    @Parent(key: "business_id")
    var business: Business

    init() {}

    init(
        id: UUID? = nil,
        weekday: Int,
        startTime: Int,
        endTime: Int,
        isClosed: Bool,
        businessID: Business.IDValue
    ) {
        self.id = id
        self.weekday = weekday
        self.startTime = startTime
        self.endTime = endTime
        self.isClosed = isClosed
        self.$business.id = businessID
    }
}
