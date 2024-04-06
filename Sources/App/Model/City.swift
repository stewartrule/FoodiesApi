import Fluent
import Vapor

final class City: Model, Content {
    static let schema = "cities"

    @ID(key: .id)
    var id: UUID?

    @Field(key: "name")
    var name: String

    @Parent(key: "province_id")
    var province: Province

    init() {}

    init(
        id: UUID? = nil,
        name: String,
        provinceID: Province.IDValue
    ) {
        self.id = id
        self.name = name
        self.$province.id = provinceID
    }
}
