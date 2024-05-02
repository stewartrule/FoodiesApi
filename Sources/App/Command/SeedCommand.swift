import Fakery
import Fluent
import Vapor

struct SeedCommand: AsyncCommand {
    struct Signature: CommandSignature {}

    var help: String { "Seed database with mock data" }

    func run(using context: CommandContext, signature: Signature) async throws {
        let faker = Faker(locale: "nl")
        let app = context.application
        let database = app.db
        let console = context.console
        let password = "foodies"
        let passwordHash = try Bcrypt.hash(password)
        var users: [(email: String, area: PostalArea)] = []

        // MARK: Gather input data
        let jsonResource = JsonResource(
            app: app,
            fileManager: FileManager.default
        )
        var postalCodes = try jsonResource.getPostalCode()
        let restaurants = try jsonResource.getRestaurants()
        let allDishes = try jsonResource.getDishes()
        let provincesNames = postalCodes.map({ $0.province.rawValue }).uniqued()
            .map({ $0 }).sorted()

        // MARK: Determine density
        let province = console.choose(
            "Province(s)",
            from: provincesNames + ["All"]
        )
        if province == "All" {
            let density = console.choose(
                "Density",
                from: ["Low", "Medium", "High", "Very high"]
            )
            let divisor =
                switch density { case "Low": 22 case "Medium": 11 case "High": 4
                    case "Very high": 1
                    default: 11
                }
            postalCodes = postalCodes.filter({ $0.postalCode % divisor == 0 })
        }
        else {
            postalCodes = postalCodes.filter({
                $0.province.rawValue == province
            })
        }

        // MARK: Create provinces
        let provinces = provincesNames.map({ Province(name: $0) })
        try await provinces.create(on: database)
        console.output("Created provinces")

        // MARK: Create cities
        let cities = try provinces.flatMap { province in
            try postalCodes.filter({ $0.province.rawValue == province.name })
                .map({ $0.city }).uniqued()
                .compactMap { cityName in
                    City(name: cityName, provinceID: try province.requireID())
                }
        }
        try await cities.create(on: database)
        console.output("Created cities")

        // MARK: Create postal areas
        let postalAreas = try cities.flatMap { city in
            try postalCodes.filter({ $0.city == city.name })
                .compactMap { postalCode in
                    return PostalArea(
                        postalCode: postalCode.postalCode,
                        latitude: postalCode.latitude,
                        longitude: postalCode.longitude,
                        cityID: try city.requireID()
                    )
                }
        }
        try await postalAreas.create(on: database)
        console.output("Created postalAreas")

        // MARK: Create business images
        let businessImages = restaurants.map { photo in
            Image(
                name: photo.alt,
                originalId: photo.original_id,
                h: photo.hsb[0],
                s: photo.hsb[1],
                b: photo.hsb[2]
            )
        }
        try await businessImages.create(on: database)
        console.output("Created business images")

        // MARK: Create product images
        let productImages = allDishes.map { photo in
            Image(
                name: photo.alt,
                originalId: photo.original_id,
                h: photo.hsb[0],
                s: photo.hsb[1],
                b: photo.hsb[2]
            )
        }
        try await productImages.create(on: database)
        console.output("Created product images")

        // MARK: Create profile images
        var profileImages: [Image] = []
        for originalId in 1...54 {
            profileImages.append(
                Image(
                    name: "Profile \(originalId)",
                    originalId: originalId,
                    h: 49,
                    s: 12,
                    b: 51
                )
            )
        }
        try await profileImages.create(on: database)
        console.output("Created profile images")

        // MARK: Create addresses
        var addresses: [Address] = []
        let letters = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
        for postalArea in postalAreas {
            let latitude = postalArea.latitude
            let longitude = postalArea.longitude
            let address = try Address(
                street: faker.address.streetName(),
                postalCodeSuffix: String(letters.randomSample(count: 2)),
                houseNumber: faker.number.randomInt(min: 4, max: 200),
                latitude: latitude,
                longitude: longitude,
                postalAreaID: postalArea.requireID()
            )
            addresses.append(address)
        }
        try await addresses.create(on: database)
        console.output("Created addresses")

        // MARK: Create cuisines
        let cuisines = restaurants.map({ $0.cuisine }).uniqued()
            .map({ Cuisine(name: $0) })
        try await cuisines.create(on: database)
        console.output("Created cuisines")

        // MARK: Create business types
        let businessTypeNames = [
            "Bistro", "Brasserie", "Café", "Grand café", "Restaurant",
        ]
        let businessTypes = businessTypeNames.map { name in
            BusinessType(name: name)
        }
        try await businessTypes.create(on: database)
        console.output("Created businessTypes")

        // MARK: Create businesses
        var progressBar = context.console.progressBar(
            title: "Creating businesses"
        )
        var factor = 1.0 / Double(addresses.count)
        var counter = 0
        progressBar.start()
        for address in addresses {
            let cuisine = cuisines.randomElement()!
            let businessType = businessTypes.randomElement()!
            let photo = restaurants.filter({ $0.cuisine == cuisine.name })
                .randomElement()!
            let image = businessImages.first(where: {
                $0.originalId == photo.original_id
            })!
            let business = try Business(
                name:
                    "\(cuisine.name.capitalized) \(businessType.name.lowercased())",
                description: photo.alt,
                deliveryCharge: faker.number.randomInt(min: 2, max: 7) * 50,
                minimumOrderAmount: faker.number.randomInt(min: 1, max: 4)
                    * 500,
                addressID: address.requireID(),
                businessTypeID: businessType.requireID(),
                imageID: image.requireID()
            )

            // MARK: Set cuisine
            try await business.create(on: database)
            try await business.$cuisines.attach([cuisine], on: database)

            // MARK: Set opening hours
            let businessID = try business.requireID()
            let closedWeekday = faker.number.randomInt(min: 1, max: 7)
            let weekdays: [Int] = Array(1...7)
            var startTime = 60 * faker.number.randomInt(min: 16, max: 18)
            var endTime = 60 * faker.number.randomInt(min: 22, max: 23)
            if businessType.name == "Bistro" {
                startTime = 60 * faker.number.randomInt(min: 10, max: 14)
                endTime = 60 * faker.number.randomInt(min: 18, max: 20)
            }

            for weekday in weekdays {
                let hours = OpeningHours(
                    weekday: weekday,
                    startTime: startTime,
                    endTime: endTime,
                    isClosed: weekday == closedWeekday,
                    businessID: businessID
                )
                try await hours.create(on: database)
            }
            try await business.save(on: database)

            progressBar.activity.currentProgress = factor * Double(counter)
            counter += 1
        }
        progressBar.succeed()

        let businesses: [Business] = try await Business.query(on: database)
            .with(\.$cuisines)
            .with(\.$products)
            .with(\.$address) { a in
                a.with(\.$postalArea) { p in
                    p.with(\.$city)
                }
            }
            .all()

        // MARK: Add relations to businesses
        progressBar = context.console.progressBar(
            title: "Adding a lot of relations"
        )
        factor = 1.0 / Double(businesses.count)
        counter = 0
        progressBar.start()

        for business in businesses {
            // Create combo
            let combo = try ProductType(
                name: "Combo",
                businessID: business.requireID()
            )
            try await combo.save(on: database)

            // Gather dishes for cuisine
            let cuisines = business.cuisines
            let dishes =
                allDishes
                .filter({ $0.cuisine == cuisines.first?.name })

            // Add product types to business
            let productTypes = try dishes.uniqued(on: { $0.dishtype })
                .map({
                    ProductType(
                        name: $0.dishtype,
                        businessID: try business.requireID()
                    )
                })
            try await productTypes.create(on: database)

            // Add products to business.
            let products = try dishes.compactMap { dish in
                let image = productImages.first(where: {
                    $0.originalId == dish.original_id
                })!

                if let productType = productTypes.first(where: {
                    $0.name == dish.dishtype
                }) {
                    return try Product(
                        name: productType.name,
                        description: dish.alt,
                        price: (faker.number.randomInt(min: 3, max: 21) * 100)
                            + 99,
                        businessID: business.requireID(),
                        productTypeID: productType.requireID(),
                        imageID: image.requireID()
                    )
                }

                return nil
            }
            try await products.create(on: database)

            // MARK: Add some discounts
            let percentage = faker.number.randomInt(min: 1, max: 4) * 10
            let discount = Discount(
                name: "\(percentage)% Off",
                percentage: percentage,
                businessID: try business.requireID(),
                onlineDate: faker.date.backward(days: 1),
                offlineDate: faker.date.forward(13)
            )
            try await discount.create(on: database)
            let discounted =
                try products.filter({ _ in
                    faker.number.randomInt(min: 1, max: 7) == 3
                })
                .map { product in
                    try ProductDiscount(
                        productID: product.requireID(),
                        discountID: discount.requireID()
                    )
                }
            try await discounted.create(on: database)

            // MARK: Add combo products
            let usedProductTypeIds = products.map(\.$productType.id).uniqued()
                .compactMap({ $0 })

            for cuisine in cuisines {
                for i in 1...3 {
                    let children = usedProductTypeIds.randomSample(count: 3)
                        .compactMap({ productType in
                            products.first(where: {
                                $0.$productType.id == productType
                            })
                        })

                    if let imageID = children.first?.$image.id {
                        let total = children.map(\.price).reduce(0, +)
                        let parent = Product(
                            name: "Combo \(i)",
                            description: "\(cuisine.name) combo",
                            price: total - 300,
                            businessID: try business.requireID(),
                            productTypeID: try combo.requireID(),
                            imageID: imageID
                        )
                        try await parent.create(on: database)
                        try await parent.$products.attach(
                            children,
                            on: database
                        )
                        try await parent.save(on: database)
                    }

                }
            }

            // MARK: Create some customers
            var customers: [Customer] = []
            let randomAreas =
                postalAreas.filter({
                    $0.$city.id == business.address.postalArea.city.id
                })
                .randomSample(count: 2)

            for postalArea in randomAreas {
                let customerImage = profileImages.randomElement()!
                let courierImage = profileImages.randomElement()!

                // MARK: Create customer
                let firstName = faker.name.firstName()
                let lastName = faker.name.lastName()
                let domain = faker.internet.domainName(true)
                let email =
                    "\(firstName.lowercased()).\(lastName.lowercased()).\(postalArea.postalCode)@\(domain)"
                let customer = try Customer(
                    firstName: firstName,
                    lastName: lastName,
                    email: email,
                    telephone:
                        "06\(faker.number.randomInt(min: 12_345_678, max: 98_765_432))",
                    passwordHash: passwordHash,
                    imageID: customerImage.requireID()
                )
                try await customer.create(on: database)

                // Add user for login.
                users.append((email, postalArea))

                // Add one address to each customer
                let address = try Address(
                    street: faker.address.streetName(),
                    postalCodeSuffix: String(letters.randomSample(count: 2)),
                    houseNumber: faker.number.randomInt(min: 4, max: 200),
                    latitude: postalArea.latitude,
                    longitude: postalArea.longitude,
                    postalAreaID: postalArea.requireID()
                )
                try await address.save(on: database)
                try await customer.$addresses.attach([address], on: database)
                try await customer.save(on: database)
                customers.append(customer)

                // MARK: Create courier
                let courier = Courier(
                    firstName: faker.name.firstName(),
                    lastName: faker.name.lastName(),
                    telephone:
                        "06\(faker.number.randomInt(min: 12_345_678, max: 98_765_432))",
                    imageID: try courierImage.requireID()
                )
                try await courier.save(on: database)

                // MARK: Add order for every delivery step
                let localBusinesses =
                    businesses.filter { business in
                        business.address.postalArea.$city.id
                            == postalArea.$city.id
                    }
                    .randomSample(count: 5)

                for index in localBusinesses.indices {
                    let business = localBusinesses[index]
                    let order = try Order(
                        customerID: customer.requireID(),
                        businessID: business.requireID(),
                        addressID: address.requireID()
                    )
                    let createdAt = faker.date.backward(days: index)
                        .addingTimeInterval(
                            faker.number.randomDouble(min: 0, max: 60) * 120.0
                        )
                    let sentAt = createdAt.addingTimeInterval(20.0 * 60)
                    order.createdAt = createdAt
                    order.$courier.id = courier.id
                    order.preparedAt =
                        index > 0 ? createdAt.addingTimeInterval(5.0 * 60) : nil
                    order.sentAt = index > 1 ? sentAt : nil
                    order.deliveredAt =
                        index > 2
                        ? createdAt.addingTimeInterval(30.0 * 60) : nil
                    try await order.save(on: database)
                    order.createdAt = createdAt
                    try await order.save(on: database)

                    // MARK: Add products to order
                    let selection = products.randomSample(count: 5)
                    for product in selection {
                        let orderedProduct = try ProductOrder(
                            quantity: faker.number.randomInt(min: 1, max: 4),
                            price: product.price,
                            productID: product.requireID(),
                            orderID: order.requireID()
                        )
                        try await orderedProduct.save(on: database)
                    }

                    // MARK: Add review for every order
                    let review = try BusinessReview(
                        review: faker.lorem.paragraph(sentencesAmount: 2),
                        rating: Double(faker.number.randomInt(min: 1, max: 5)),
                        isAnonymous: faker.number.randomBool(),
                        businessID: business.requireID(),
                        customerID: customer.requireID(),
                        orderID: order.requireID()
                    )
                    try await review.save(on: database)

                    // MARK: Add chat conversation
                    for i in 0...3 {
                        let chat = try Chat(
                            orderID: order.requireID(),
                            customerID: customer.requireID(),
                            courierID: courier.requireID(),
                            message: faker.lorem.sentence(),
                            sender: i % 2 == 0 ? .customer : .courier
                        )

                        try await chat.save(on: database)
                        chat.createdAt = sentAt.addingTimeInterval(
                            Double(i + 2) * 60
                        )
                        chat.seenAt =
                            i < 3
                            ? sentAt.addingTimeInterval(Double(i + 3) * 60)
                            : nil
                        try await chat.save(on: database)
                    }
                }
            }

            progressBar.activity.currentProgress = factor * Double(counter)
            counter += 1
        }
        progressBar.succeed()

        // MARK: Finish up
        console.output("You can now log in with one of the following accounts:")
        for user in users.enumerated()
            .filter({ index, user in index % 20 == 0 }).map({ $1 })
        {
            let city = try await user.area.$city.get(on: database)
            console.output(
                "\(user.email) (\(city.name))",
                style: .info,
                newLine: true
            )
        }
        console.output("Your password: \(password)", style: .success)
    }
}
