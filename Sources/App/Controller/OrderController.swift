import Fluent
import Vapor

struct OrderController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let tokenProtected = routes.grouped(CustomerToken.authenticator())
        let group = tokenProtected.grouped(.constant(Order.schema))

        group.group("reviews") { group in
            group.post(use: addReview)
        }

        group.group("chats") { group in
            group.post(use: addChat)
        }
    }

    func addChat(req: Request) async throws -> Chat {
        let customer = try req.auth.require(Customer.self)

        try AddChat.validate(content: req)
        let body = try req.content.decode(AddChat.self)
        let customerID = try customer.requireID()

        guard
            let order = try await req.orderRepository.firstBy(
                customerID: customerID,
                orderID: body.orderID
            )
        else {
            throw Abort(.notFound)
        }

        guard let courier = order.courier else {
            throw Abort(.badRequest)
        }

        let chat = Chat(
            orderID: try order.requireID(),
            customerID: customerID,
            courierID: try courier.requireID(),
            message: body.message,
            sender: .customer
        )
        try await chat.save(on: req.db)

        return chat
    }

    func updateReview(req: Request) async throws -> ReviewContent {
        let customer = try req.auth.require(Customer.self)

        try UpdateReview.validate(content: req)
        let body = try req.content.decode(UpdateReview.self)

        guard
            let review = try await req.orderReviewRepository.firstBy(
                profileID: try customer.requireID(),
                reviewID: body.reviewID
            )
        else {
            throw Abort(.notFound)
        }

        review.review = body.review
        review.rating = Double(body.rating)
        review.isAnonymous = body.isAnonymous
        try await review.save(on: req.db)

        return try ReviewContent.from(review: review)
    }

    func addReview(req: Request) async throws -> ReviewContent {
        let customer = try req.auth.require(Customer.self)

        try AddReview.validate(content: req)
        let body = try req.content.decode(AddReview.self)
        let customerID = try customer.requireID()

        guard
            let order = try await req.orderRepository.firstBy(
                customerID: customerID,
                orderID: body.orderID
            )
        else {
            throw Abort(.notFound)
        }

        // Fixme: maybe do this on time?
        if order.deliveredAt == nil {
            throw Abort(.badRequest)
        }

        let review = OrderReview(
            review: body.review,
            rating: Double(body.rating),
            isAnonymous: body.isAnonymous,
            businessID: try order.business.requireID(),
            customerID: customerID,
            orderID: try order.requireID()
        )
        try await review.save(on: req.db)

        return try ReviewContent.from(review: review)
    }
}
