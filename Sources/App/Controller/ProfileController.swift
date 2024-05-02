import Fluent
import Vapor

struct ProfileController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let tokenProtected = routes.grouped(CustomerToken.authenticator())
        let routes = tokenProtected.grouped(.constant("profile"))

        routes.get(use: profile)
        routes.group("orders") { routes in
            routes.get(use: orders)
            routes.get(":orderID", use: order)
        }
    }

    private func getProfile(req: Request) async throws -> Customer? {
        let customer = try req.auth.require(Customer.self)
        return try await req.profileRepository.getProfile(
            for: customer
        )
    }

    func profile(req: Request) async throws -> ProfileContent {
        guard let profile = try await getProfile(req: req) else {
            throw Abort(.unauthorized)
        }

        guard
            let orders = try await req.profileRepository.getPendingOrders(
                for: profile
            )
        else {
            throw Abort(.notFound)
        }

        return try await ProfileContent.from(
            req: req,
            profile: profile,
            pendingOrders: orders.asyncMap({ order in
                try await OrderContent.from(req: req, order: order)
            })
        )
    }

    func orders(req: Request) async throws -> Page<OrderContent> {
        guard let profile = try await getProfile(req: req) else {
            throw Abort(.unauthorized)
        }

        guard
            let orders = try await req.profileRepository.getOrders(for: profile)
        else {
            throw Abort(.notFound)
        }

        return try await orders.asyncMap { order in
            try await OrderContent.from(req: req, order: order)
        }
    }

    func order(req: Request) async throws -> OrderContent {
        guard let profile = try await getProfile(req: req) else {
            throw Abort(.unauthorized)
        }

        guard let orderID = req.parameters.get("orderID", as: UUID.self) else {
            throw Abort(.badRequest)
        }

        guard
            let order = try await req.profileRepository.getOrder(
                for: profile,
                orderID: orderID
            )
        else { throw Abort(.notFound) }

        return try await OrderContent.from(req: req, order: order)
    }
}
