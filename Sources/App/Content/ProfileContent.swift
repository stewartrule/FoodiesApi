import Vapor

struct ProfileContent: Content {
    struct Profile: Codable {
        let id: UUID
        let firstName: String
        let lastName: String
        let telephone: String
        let email: String
        let addresses: [Address]
        let image: ImageContent?
    }

    let profile: Profile
    let pendingOrders: [OrderContent]

    static func from(
        req: Request,
        profile: Customer,
        pendingOrders: [OrderContent]
    ) throws -> ProfileContent {
        var imageContent: ImageContent?
        if profile.$image.value != nil, let image = profile.image {
            imageContent = try ImageContent.from(req: req, image: image)
        }

        return .init(
            profile: Profile(
                id: try profile.requireID(),
                firstName: profile.firstName,
                lastName: profile.lastName,
                telephone: profile.telephone,
                email: profile.telephone,
                addresses: profile.addresses,
                image: imageContent
            ),
            pendingOrders: pendingOrders
        )
    }
}
