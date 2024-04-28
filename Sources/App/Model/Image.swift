import Fluent
import Vapor

final class Image: Model, Content {
    static let schema = "images"

    @ID(key: .id) var id: UUID?

    @Field(key: "name") var name: String

    @Field(key: "original_id") var originalId: Int

    @Field(key: "h") var h: Int

    @Field(key: "s") var s: Int

    @Field(key: "b") var b: Int

    init() {}

    init(
        id: UUID? = nil,
        name: String,
        originalId: Int,
        h: Int = 0,
        s: Int = 0,
        b: Int = 0
    ) {
        self.id = id
        self.name = name
        self.originalId = originalId
        self.h = h
        self.s = s
        self.b = b
    }
}
