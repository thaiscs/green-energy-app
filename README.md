# README

## Quick start

**Rails**

```bash
    bundle install
```

```bash
    bin/rails server
```

**Create Database and Seed**

```bash
docker run --name greenenergy_dev -e POSTGRES_PASSWORD=postgres \
  -p 5432:5432 -d postgres:18
```

```bash
    bin/rails db:prepare
```

**Import Data**

```bash
    bin/rails runner 'ImportConsumptionDataDispatcherJob.perform_now'
```

```bash
    tail -f log/development.log
```