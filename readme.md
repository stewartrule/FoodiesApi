## Foodies Api

Trying out [Vapor](https://vapor.codes) as the backend for [Foodies IOS](https://github.com/stewartrule/FoodiesIOS)

### Setup environment.

```bash
docker-compose build --build
```

### Setup database

```bash
swift run App migrate
```

### Seed

```bash
swift run App seed
```

Pick a province.

```bash
Province(s)
1: Drenthe
2: Flevoland
3: Friesland
4: Gelderland
5: Groningen
6: Limburg
7: Noord-Brabant
8: Noord-Holland
9: Overijssel
10: Utrecht
11: Zeeland
12: Zuid-Holland
13: All
>
```

Every province takes around 90 seconds to seed. If you pick `All` you'll be asked to pick a density.

```bash
Density
1: Low // ~20 seconds
2: Medium // ~1 minute
3: High // ~3 minutes
4: Very high // 15+ minutes
>
```

### Run app

```bash
swift run App
```
