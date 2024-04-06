import Fluent
import Vapor

func routes(_ app: Application) throws {
    try app.register(collection: PostalAreaController())
    try app.register(collection: ProductController())
    try app.register(collection: BusinessController())
    try app.register(collection: BusinessReviewController())
    try app.register(collection: OrderController())

    app.get { req async in
        app.routes.all.map({ $0.description })
    }

    /*

    /businesses
    /businesses/:uuid
    /businesses/:uuid/reviews
    /businesses/:uuid/customers
    /businesses/:uuid/customers/:uuid
    /businesses/:uuid/orders
    /businesses/:uuid/orders/:uuid

    /customers/:uuid
    /customers/:uuid/orders
    /customers/:uuid/orders/:uuid
    /customers/:uuid/chats
    /customers/:uuid/chats/:uuid

    /postal_areas

    */
}
