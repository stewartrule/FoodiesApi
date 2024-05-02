import Fluent
import Vapor

struct LoginController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let passwordProtected = routes.grouped(Customer.authenticator())

        passwordProtected.post("login") { req -> CustomerToken in
            let customer = try req.auth.require(Customer.self)
            let token = try customer.generateToken()
            try await token.save(on: req.db)
            return token
        }
    }
}
