# Solar self-consumption for one consumer (unit), computed in a single SQL pass.
#
#     solar = metering measurements (total consumption) - market measurements (grid exchange)
#
# Conditional aggregation collapses every measurement into one row, so no
# measurement records are loaded into Ruby.
class SolarConsumptionReport
  METERING = "MeteringLocation"
  MARKET   = "MarketLocation"

  TOTAL_SOLAR_KWH = <<~SQL.squish
    COALESCE(SUM(measurements.value_kwh) FILTER (WHERE locations.type = '#{METERING}'), 0)
    - COALESCE(SUM(measurements.value_kwh) FILTER (WHERE locations.type = '#{MARKET}'), 0)
  SQL

  Timeframe = Data.define(:starts_at, :ends_at) do
    def present?
      starts_at.present? && ends_at.present?
    end

    def days
      return 0 unless present?

      inclusive_day_span.clamp(1..)
    end

    private

    def inclusive_day_span
      (ends_at.to_date - starts_at.to_date).to_i + 1
    end
  end

  Result = Data.define(:total_solar_kwh, :timeframe, :solar_by_day) do
    def average_daily_kwh
      return BigDecimal(0) unless timeframe.present?

      total_solar_kwh / timeframe.days
    end

    def daily_solar(day)
      solar_by_day.fetch(day.to_date, BigDecimal(0))
    end
  end

  # Backstop only. Correctness comes from the fingerprint in the cache key, not
  # from expiry — this just bounds how long an orphaned entry can linger.
  CACHE_TTL = 12.hours

  def initialize(unit)
    @unit = unit
  end

  def call
    Rails.cache.fetch(cache_key, expires_in: CACHE_TTL) do
      build_result(select_one(relation), select_all(daily_relation))
    end
  end

  private

  # Keyed on a fingerprint of the unit's measurements, so the entry invalidates
  # itself the moment the importer upserts new rows (updated_at moves) or the row
  # count changes.
  def cache_key
    max_updated_at, count = measurements.pick(
      Arel.sql("MAX(measurements.updated_at)"),
      Arel.sql("COUNT(*)")
    )

    [ "solar_consumption_report", "v1", @unit.id, count, max_updated_at.to_f ]
  end

  def measurements
    Measurement.joins(:location).where(locations: { unit_id: @unit.id })
  end

  def build_result(row, daily_rows)
    timeframe = Timeframe.new(
      starts_at: to_application_zone(row["starts_at"]),
      ends_at:   to_application_zone(row["ends_at"])
    )

    # Self-consumption is only defined where the meter reported. With no metering
    # `metering - market` would be a meaningless negative so report nothing rather than a phantom deficit.
    return empty_result unless timeframe.present?

    Result.new(
      total_solar_kwh: BigDecimal(row["total_solar_kwh"].to_s),
      timeframe:,
      solar_by_day: solar_by_day(daily_rows)
    )
  end

  def empty_result
    Result.new(
      total_solar_kwh: BigDecimal(0),
      timeframe: Timeframe.new(starts_at: nil, ends_at: nil),
      solar_by_day: {}
    )
  end

  def solar_by_day(daily_rows)
    daily_rows.each_with_object({}) do |row, by_day|
      by_day[row["day"].to_date] = BigDecimal(row["solar_kwh"].to_s)
    end
  end

  def select_one(relation)
    ActiveRecord::Base.connection.select_one(relation.to_sql)
  end

  def select_all(relation)
    ActiveRecord::Base.connection.select_all(relation.to_sql)
  end

  # Raw SQL skips ActiveRecord's casting, so timestamps arrive as UTC.
  def to_application_zone(value)
    return if value.nil?

    parse_utc(value).in_time_zone
  end

  def parse_utc(value)
    value.is_a?(String) ? Time.find_zone!("UTC").parse(value) : value
  end

  def relation
    measurements.select(
      "#{TOTAL_SOLAR_KWH} AS total_solar_kwh",
      "MIN(measurements.starts_at) FILTER (WHERE locations.type = '#{METERING}') AS starts_at",
      "MAX(measurements.starts_at) FILTER (WHERE locations.type = '#{METERING}') AS ends_at"
    )
  end

  def daily_relation
    measurements
      .group(Arel.sql(local_day))
      .select("#{local_day} AS day", "#{TOTAL_SOLAR_KWH} AS solar_kwh")
  end

  def local_day
    "(measurements.starts_at AT TIME ZONE '#{Time.zone.tzinfo.name}')::date"
  end
end
