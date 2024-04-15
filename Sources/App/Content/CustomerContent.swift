import Vapor

struct CustomerContent: Content {
    let firstName: String
    let lastName: String

    static func from(customer: Customer) -> Self {
        CustomerContent(
            firstName: customer.firstName,
            lastName: customer.lastName
        )
    }
}
