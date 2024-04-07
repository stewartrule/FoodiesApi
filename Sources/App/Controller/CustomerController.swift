import Fluent
import Vapor

struct CustomerController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let a = routes.grouped(.constant(Customer.schema))
        a.group(":customerID") { b in
            b.get(use: customer)
            b.group("orders") { c in
                c.get(use: orders)
                c.group(":orderID") { d in
                    d.get(use: order)
                    d.get("chats", use: chats)
                }
            }
        }
    }

    func orders(req: Request) async throws -> Page<Order> {
        guard let customerID = req.parameters.get("customerID", as: UUID.self)
        else { throw Abort(.badRequest) }

        let orders = try await Order.query(on: req.db)
            .filter(\.$customer.$id == customerID).with(\.$customer)
            .with(\.$courier).sort(\.$createdAt, .descending).paginate(for: req)

        return orders
    }

    func chats(req: Request) async throws -> Page<Chat> {
        guard let customerID = req.parameters.get("customerID", as: UUID.self)
        else { throw Abort(.badRequest) }
        guard let orderID = req.parameters.get("orderID", as: UUID.self) else {
            throw Abort(.badRequest)
        }

        let chats = try await Chat.query(on: req.db)
            .filter(\.$order.$id == orderID)
            .filter(\.$customer.$id == customerID)
            .sort(\.$createdAt, .descending).paginate(for: req)

        return chats
    }

    func order(req: Request) async throws -> Order {
        guard let customerID = req.parameters.get("customerID", as: UUID.self)
        else { throw Abort(.badRequest) }
        guard let orderID = req.parameters.get("orderID", as: UUID.self) else {
            throw Abort(.badRequest)
        }

        guard
            let order = try await Order.query(on: req.db)
                .filter(\.$id == orderID).filter(\.$customer.$id == customerID)
                .with(\.$courier).with(\.$business)
                .with(
                    \.$items,
                    { item in
                        item.with(\.$product) { product in
                            product.with(\.$productType).with(\.$discounts)
                                .with(
                                    \.$products,
                                    { rel in rel.with(\.$productType) }
                                )
                        }
                    }
                )
                .first()
        else { throw Abort(.notFound) }

        return order
    }

    func customer(req: Request) async throws -> Customer {
        guard let customerID = req.parameters.get("customerID", as: UUID.self)
        else { throw Abort(.badRequest) }

        guard
            let customer = try await Customer.query(on: req.db)
                .filter(\.$id == customerID)
                .with(
                    \.$addresses,
                    { addresses in
                        addresses.with(
                            \.$postalArea,
                            { postalArea in
                                postalArea.with(
                                    \.$city,
                                    { city in city.with(\.$province) }
                                )
                            }
                        )
                    }
                )
                .first()
        else { throw Abort(.notFound) }

        return customer
    }
}
