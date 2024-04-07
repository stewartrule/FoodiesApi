import Fluent
import FluentPostgresDriver
import NIOSSL
import Vapor

public func configure(_ app: Application) async throws {
    // uncomment to serve files from /Public folder
    // app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory))

    app.databases.use(
        .postgres(
            configuration: .init(
                hostname: Environment.get("DATABASE_HOST")
                    ?? "localhost",
                port: Environment.get("DATABASE_PORT")
                    .flatMap(Int.init(_:))
                    ?? SQLPostgresConfiguration
                    .ianaPortNumber,
                username: Environment.get(
                    "DATABASE_USERNAME"
                )
                    ?? "vapor_username",
                password: Environment.get(
                    "DATABASE_PASSWORD"
                )
                    ?? "vapor_password",
                database: Environment.get("DATABASE_NAME")
                    ?? "vapor_database",
                tls: .prefer(
                    try .init(configuration: .clientDefault)
                )
            )
        ),
        as: .psql
    )

    app.asyncCommands.use(SeedCommand(), as: "seed")

    let migrations: [AsyncMigration] = [
        CreateProductType(),
        CreateBusinessType(),
        CreateCuisine(),
        CreateProvince(),
        CreateCity(),
        CreatePostalArea(),
        CreateAddress(),
        CreateBusiness(),
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
    ]

    for migration in migrations {
        app.migrations.add(migration)
    }

    try routes(app)
}
