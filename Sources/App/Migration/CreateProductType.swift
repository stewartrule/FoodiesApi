import Fluent

struct CreateProductType: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema(ProductType.schema)
            .id()
            .field("name", .string, .required)
            .create()
    }

    func revert(on database: Database) async throws {
        try await database.schema(ProductType.schema).delete()
    }
}
