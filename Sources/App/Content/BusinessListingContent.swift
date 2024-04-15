import Vapor

struct BusinessListingContent: Content {
    let center: CoordinateContent
    let businesses: [BusinessContent]
}
