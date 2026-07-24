# README

## Quick start

**Database**

```bash
docker run --name greenenergy_dev -e POSTGRES_PASSWORD=postgres \
  -p 5432:5432 -d postgres:18
```

```bash
    bin/rails db:prepare
```bash

