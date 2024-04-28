import Fluent
import Vapor

struct ProfileController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let group = routes.grouped(.constant("profile"))
        group.get(use: profile)
        group.group("orders") { subgroup in
            subgroup.get(use: orders)
            subgroup.get(":orderID", use: order)
        }
    }

    // todo: handle login
    func profile(req: Request) async throws -> ProfileContent {
        guard let profile = try await req.profileRepository.getProfile() else {
            throw Abort(.notFound)
        }
        guard let orders = try await req.profileRepository.getPendingOrders()
        else { throw Abort(.notFound) }

        return try await ProfileContent.from(
            req: req,
            profile: profile,
            pendingOrders: orders.asyncMap({ order in
                try await OrderContent.from(req: req, order: order)
            })
        )
    }

    // todo: handle login
    func orders(req: Request) async throws -> Page<OrderContent> {
        guard let orders = try await req.profileRepository.getOrders() else {
            throw Abort(.notFound)
        }

        return try await orders.asyncMap { order in
            try await OrderContent.from(req: req, order: order)
        }
    }

    // todo: handle login
    func order(req: Request) async throws -> OrderContent {
        guard let orderID = req.parameters.get("orderID", as: UUID.self) else {
            throw Abort(.badRequest)
        }

        guard
            let order = try await req.profileRepository.getOrder(
                orderID: orderID
            )
        else { throw Abort(.notFound) }

        return try await OrderContent.from(req: req, order: order)
    }
}
