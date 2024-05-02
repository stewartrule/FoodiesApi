import Fluent
import FluentPostgresDriver
import Vapor

extension Request {
    var baseUrl: String {
        let configuration = application.http.server.configuration
        let scheme = configuration.tlsConfiguration == nil ? "http" : "https"
        let host = configuration.hostname
        let port = configuration.port
        return "\(scheme)://\(host):\(port)"
    }
}

public func configure(_ app: Application) async throws {
    app.middleware.use(
        FileMiddleware(publicDirectory: app.directory.publicDirectory)
    )

    app.databases.use(
        .postgres(
            configuration: .init(
                hostname: Environment.get("DATABASE_HOST") ?? "localhost",
                port: Environment.get("DATABASE_PORT").flatMap(Int.init(_:))
                    ?? SQLPostgresConfiguration.ianaPortNumber,
                username: Environment.get("DATABASE_USERNAME")
                    ?? "vapor_username",
                password: Environment.get("DATABASE_PASSWORD")
                    ?? "vapor_password",
                database: Environment.get("DATABASE_NAME") ?? "vapor_database",
                tls: .prefer(try .init(configuration: .clientDefault))
            )
        ),
        as: .psql
    )

    app.asyncCommands.use(SeedCommand(), as: "seed")

    let migrations: [AsyncMigration] = [
        CreateImage(),
        CreateBusinessType(),
        CreateCuisine(),
        CreateProvince(),
        CreateCity(),
        CreatePostalArea(),
        CreateAddress(),
        CreateBusiness(),
        CreateProductType(),
        CreateBusinessCuisine(),
        CreateProduct(),
        CreateProductCombo(),
        CreateCustomer(),
        CreateCustomerAddress(),
        CreateCourier(),
        CreateOrder(),
        CreateProductOrder(),
        CreateBusinessReview(),
        CreateOpeningHours(),
        CreateDiscount(),
        CreateProductDiscount(),
        CreateChat(),
        CreateCustomerToken(),
    ]

    for migration in migrations { app.migrations.add(migration) }

    try routes(app)
}
