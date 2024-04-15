import Fluent
import Vapor

struct CustomerController: RouteCollection {
    let customerIDParam = "customerID"
    let orderIDParam = "orderID"

    func boot(routes: RoutesBuilder) throws {
        let group = routes.grouped(.constant(Customer.schema))
        group.group(":\(customerIDParam)") { sg1 in
            sg1.get(use: customer)
            sg1.group("orders") { sg2 in
                sg2.get(use: orders)
                sg2.group(":\(orderIDParam)") { sg3 in
                    sg3.get(use: order)
                    sg3.get("chats", use: chats)
                }
            }
        }
    }

    func orders(req: Request) async throws -> Page<Order> {
        guard
            let customerID = req.parameters.get(customerIDParam, as: UUID.self)
        else { throw Abort(.badRequest) }

        return try await req.customerRepository.getOrders(
            customerID: customerID
        )
    }

    func chats(req: Request) async throws -> Page<Chat> {
        guard
            let customerID = req.parameters.get(customerIDParam, as: UUID.self)
        else { throw Abort(.badRequest) }
        guard let orderID = req.parameters.get(orderIDParam, as: UUID.self)
        else { throw Abort(.badRequest) }

        return try await req.customerRepository.getChats(
            customerID: customerID,
            orderID: orderID
        )
    }

    func order(req: Request) async throws -> Order {
        guard
            let customerID = req.parameters.get(customerIDParam, as: UUID.self)
        else { throw Abort(.badRequest) }
        guard let orderID = req.parameters.get(orderIDParam, as: UUID.self)
        else { throw Abort(.badRequest) }

        guard
            let order = try await req.customerRepository.getOrder(
                customerID: customerID,
                orderID: orderID
            )
        else { throw Abort(.notFound) }

        return order
    }

    func customer(req: Request) async throws -> Customer {
        guard
            let customerID = req.parameters.get(customerIDParam, as: UUID.self)
        else { throw Abort(.badRequest) }

        guard
            let customer = try await req.customerRepository.find(
                customerID: customerID
            )
        else { throw Abort(.notFound) }

        return customer
    }
}
