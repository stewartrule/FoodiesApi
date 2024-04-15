## Foodies Api

Trying out [Vapor](https://vapor.codes) as the backend for ... (hopefully soon)

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
1: All
2: Drenthe
3: Friesland
4: Gelderland
5: Groningen
6: Limburg
7: Noord-Brabant
8: Noord-Holland
9: Utrecht
10: Zeeland
11: Zuid-Holland
12: Overijssel
13: Flevoland
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
