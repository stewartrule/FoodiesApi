import Fluent
import Vapor

// @todo
final class Image: Model, Content {
    static let schema = "images"

    @ID(key: .id) var id: UUID?

    @Field(key: "name") var name: String

    @Field(key: "original_id") var originalId: Int

    @Field(key: "avg_color") var avgColor: String

    init() {}

    init(id: UUID? = nil, name: String, originalId: Int, avgColor: String) {
        self.id = id
        self.name = name
        self.originalId = originalId
        self.avgColor = avgColor
    }
}
