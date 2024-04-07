import Fluent
import Vapor

final class ProductCombo: Model, Content {
    static let schema = "product_combo"

    @ID(key: .id) var id: UUID?

    @Parent(key: "parent_id") var parent: Product

    @Parent(key: "child_id") var child: Product

    init() {}

    init(id: UUID? = nil, parentID: Product.IDValue, childID: Product.IDValue) {
        self.id = id
        self.$parent.id = parentID
        self.$child.id = childID
    }
}
