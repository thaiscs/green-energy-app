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

## Possible Improvements

**Auth based access with Multi-Tenancy**

I would use `Devise` gem to hide access to the application behind an authentication
engine that already comes with self-registration, rate-limiter, lock-account features
backed in, in comparison with rails built-in authentication.

On top of that, only internal `admin` or `superuser` should have access to all data. So adding multi-tenancy with `act_as_tenant` gem makes a lot of sense here to handle users that are `owner` and users that are `tenant` and therefore should only see consumption data related to their house.

Constraints worth looking into are raw `sql` and `jobs` bypassing the `default_scope`
that act_as_tenant implements under the hood.

Possible solutions involve creating explicit role-aware accessors like below:

```ruby
def accessible_units
  owner? ? Unit.all : Unit.where(id: unit_id)        # Unit.all already account-scoped
end

def accessible_buildings
  owner? ? Building.all : Building.where(id: unit&.building_id)
end
```

**Sidekiq + Redis**

For the `ImportData` background job I'm using the already built-in Solid Queue that uses the database instead of Redis. For speed in completing the assignment I let it use the default postresql but I know the separation is recommended to isolate read x write load. Nevertheless, the competition for DB connection would still be a bottleneck, so I think Sidekiq would be a better fit here, because Redis is faster +
you get audit trail with UI out of the box.

**Monitoring with AppSignal**

For a full APM (traces, DB timing, throughput) with error tracking bundled in, I'd add the `gem "appsignal"` in `config` with the business `API_KEY` so Rails controllers, ActiveRecord, and Active Job get traced automatically.

**Deployment**

I would go `Heroku` dynos with managed `Postgresql`, `Sidekiq`, `Redis` and `AppSignal` add-ons. It's a one-stop shop for easy to manage infra + CI/CD and metrics out of the box.
