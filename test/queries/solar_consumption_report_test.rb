require "test_helper"

class SolarConsumptionReportTest < ActiveSupport::TestCase
  setup do
    Measurement.delete_all
    @unit = units(:apartment_1)

    # Two calendar days of data. Solar = metering - market = 10 - 4 = 6 kWh,
    # spanning 2 days => 3 kWh/day.
    add_measurement(locations(:apartment_1_metering), "2026-06-01T00:00:00Z", 6)
    add_measurement(locations(:apartment_1_metering), "2026-06-02T00:00:00Z", 4)
    add_measurement(locations(:apartment_1_market),   "2026-06-01T00:00:00Z", 1)
    add_measurement(locations(:apartment_1_market),   "2026-06-02T00:00:00Z", 3)
  end

  test "computes total solar as metering minus market" do
    result = SolarConsumptionReport.new(@unit).call

    assert_equal BigDecimal("6"), result.total_solar_kwh
  end

  test "computes average daily solar over the timeframe" do
    result = SolarConsumptionReport.new(@unit).call

    assert_equal 2, result.timeframe.days
    assert_equal BigDecimal("3"), result.average_daily_kwh
  end

  test "exposes the timeframe the values represent" do
    result = SolarConsumptionReport.new(@unit).call

    assert_equal Date.new(2026, 6, 1), result.timeframe.starts_at.to_date
    assert_equal Date.new(2026, 6, 2), result.timeframe.ends_at.to_date
  end

  test "returns a zeroed result when the unit has no measurements" do
    result = SolarConsumptionReport.new(units(:apartment_2)).call

    assert_equal BigDecimal("0"), result.total_solar_kwh
    assert_equal BigDecimal("0"), result.average_daily_kwh
    assert_not result.timeframe.present?
  end

  test "reports nothing when the unit has market data but no metering data" do
    add_measurement(locations(:apartment_2_market), "2026-06-01T00:00:00Z", 5)

    result = SolarConsumptionReport.new(units(:apartment_2)).call

    assert_equal BigDecimal("0"), result.total_solar_kwh
    assert_equal BigDecimal("0"), result.average_daily_kwh
    assert_not result.timeframe.present?
    assert_equal BigDecimal("0"), result.daily_solar(Date.new(2026, 6, 1))
  end

  test "reports solar self-consumption for a specific day" do
    result = SolarConsumptionReport.new(@unit).call

    assert_equal BigDecimal("5"), result.daily_solar(Date.new(2026, 6, 1))
    assert_equal BigDecimal("1"), result.daily_solar(Date.new(2026, 6, 2))
  end

  test "daily_solar is zero for a day without measurements" do
    result = SolarConsumptionReport.new(@unit).call

    assert_equal BigDecimal("0"), result.daily_solar(Date.new(2026, 6, 3))
  end

  test "daily_solar accepts a time and buckets it by application-zone day" do
    result = SolarConsumptionReport.new(@unit).call

    assert_equal BigDecimal("5"), result.daily_solar(Time.zone.local(2026, 6, 1, 14, 30))
  end

  test "a cache hit skips the aggregations and runs only the fingerprint query" do
    with_memory_cache do
      SolarConsumptionReport.new(@unit).call # warm the cache

      # Second call issues only the lightweight fingerprint query; the two
      # aggregation queries (total + daily breakdown) are served from cache.
      # uncached so the fingerprint query actually runs (as it would on a fresh
      # request) rather than being served by the per-test query cache.
      result = nil
      assert_queries_count(1) do
        ActiveRecord::Base.uncached do
          result = SolarConsumptionReport.new(@unit).call
        end
      end
      assert_equal BigDecimal("6"), result.total_solar_kwh
    end
  end

  test "importing new measurements invalidates the cached result" do
    with_memory_cache do
      first = SolarConsumptionReport.new(@unit).call
      assert_equal BigDecimal("6"), first.total_solar_kwh

      # Simulate the importer upserting another metering day (+5 kWh solar).
      add_measurement(locations(:apartment_1_metering), "2026-06-03T00:00:00Z", 5)

      second = SolarConsumptionReport.new(@unit).call
      assert_equal BigDecimal("11"), second.total_solar_kwh
    end
  end

  private

  def with_memory_cache
    original = Rails.cache
    Rails.cache = ActiveSupport::Cache::MemoryStore.new
    yield
  ensure
    Rails.cache = original
  end

  def add_measurement(location, starts_at, value_kwh)
    start = Time.iso8601(starts_at)
    location.measurements.create!(starts_at: start, ends_at: start + 15.minutes, value_kwh:)
  end
end
