# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

# Seed the database from the test fixtures.
#
# Guarded to non-production environments: ActiveRecord::FixtureSet.create_fixtures
# deletes existing rows in each table before inserting, so running it in
# production would wipe real data.
#
# We skip `measurements` (per request) and the empty scaffold placeholders
# `market_locations` / `metering_locations`. MarketLocation and MeteringLocation
# are STI subclasses of Location, so their real records are loaded from
# `locations.yml` via the `type` column.
if Rails.env.production?
  warn "Skipping fixture seed: not run in production."
else
  require "active_record/fixtures"

  # Order matters: each set is referenced by the next via label associations
  # (units -> buildings, locations -> units).
  fixtures = %w[buildings units locations]

  ActiveRecord::FixtureSet.create_fixtures(Rails.root.join("test/fixtures"), fixtures)

  puts "Seeded #{fixtures.join(', ')} from test/fixtures."
end
