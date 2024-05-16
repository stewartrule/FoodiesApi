import Fluent
import Vapor

final class Image: Model, Content {
    static let schema = "images"

    @ID(key: .id) var id: UUID?

    @Field(key: "name") var name: String

    @Field(key: "src") var src: String

    @Field(key: "h") var h: Int

    @Field(key: "s") var s: Int

    @Field(key: "b") var b: Int

    init() {}

    init(
        id: UUID? = nil,
        name: String,
        src: String,
        h: Int = 0,
        s: Int = 0,
        b: Int = 0
    ) {
        self.id = id
        self.name = name
        self.src = src
        self.h = h
        self.s = s
        self.b = b
    }
}
