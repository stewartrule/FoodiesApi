import Vapor

struct ImageContent: Content {
    let id: Image.IDValue
    let name: String
    let avgColor: String
    let src: String

    static func from(req: Request, image: Image) throws -> Self {
        .init(
            id: try image.requireID(),
            name: image.name,
            avgColor: image.avgColor,
            src: "\(req.baseUrl)/images/\(image.originalId).webp"
        )
    }
}
