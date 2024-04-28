import Vapor

struct OrderContent: Content {
    struct BusinessAddressContent: Content {
        let id: Business.IDValue
        let name: String
        let address: Address
    }

    let id: UUID
    let createdAt: Date?
    let preparedAt: Date?
    let sentAt: Date?
    let deliveredAt: Date?
    let address: Address
    let business: BusinessAddressContent
    let courier: CourierContent?
    let items: [ProductOrderContent]
    let chat: [Chat]

    static func from(req: Request, order: Order) async throws -> Self {
        var courierContent: CourierContent?
        if order.$courier.value != nil, let courier = order.courier {
            courierContent = try CourierContent.from(req: req, courier: courier)
        }

        let business = order.business
        return OrderContent(
            id: try order.requireID(),
            createdAt: order.createdAt,
            preparedAt: order.preparedAt,
            sentAt: order.sentAt,
            deliveredAt: order.deliveredAt,
            address: order.address,
            business: BusinessAddressContent(
                id: try business.requireID(),
                name: business.name,
                address: business.address
            ),
            courier: courierContent,
            items: try order.items.map {
                try ProductOrderContent.from(req: req, item: $0)
            },
            chat: order.$chat.value != nil ? order.chat : []
        )
    }
}
