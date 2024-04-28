import Vapor

struct CourierContent: Codable {
    let id: UUID
    let firstName: String
    let lastName: String
    let telephone: String
    let image: ImageContent?

    static func from(req: Request, courier: Courier) throws -> CourierContent {
        var imageContent: ImageContent?
        if courier.$image.value != nil, let image = courier.image {
            imageContent = try ImageContent.from(req: req, image: image)
        }

        return .init(
            id: try courier.requireID(),
            firstName: courier.firstName,
            lastName: courier.lastName,
            telephone: courier.telephone,
            image: imageContent
        )
    }
}
