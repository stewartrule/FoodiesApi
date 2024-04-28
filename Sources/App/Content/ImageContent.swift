import Vapor

struct ImageContent: Content {
    let id: Image.IDValue
    let name: String
    let src: String
    let h: Int
    let s: Int
    let b: Int

    static func from(req: Request, image: Image) throws -> Self {
        .init(
            id: try image.requireID(),
            name: image.name,
            src: "\(req.baseUrl)/images/\(image.originalId).webp",
            h: image.h,
            s: image.s,
            b: image.b
        )
    }
}
