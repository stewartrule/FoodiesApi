import Fluent

struct CreateBusiness: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema(Business.schema).id()
            .field("name", .string, .required)
            .field("description", .string, .required)
            .field("delivery_charge", .int32, .required)
            .field("minimum_order_amount", .int32, .required)
            .field(
                "address_id",
                .uuid,
                .required,
                .references(Address.schema, "id")
            )
            .field(
                "business_type_id",
                .uuid,
                .required,
                .references(BusinessType.schema, "id")
            )
            .field(
                "image_id",
                .uuid,
                .required,
                .references(Image.schema, "id")
            )
            .create()
    }

    func revert(on database: Database) async throws {
        try await database.schema(Business.schema).delete()
    }
}
