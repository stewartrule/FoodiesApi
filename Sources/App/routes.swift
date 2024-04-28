import Fluent
import Vapor

func routes(_ app: Application) throws {
    try app.register(collection: BusinessController())
    try app.register(collection: CustomerController())
    try app.register(collection: PostalAreaController())
    try app.register(collection: ProfileController())

    app.get { req async in app.routes.all.map({ $0.description }) }
}
