class MeasurementImporter
  def initialize(location_id)
    @location_id = location_id
  end

  def call(payload)
    rows = build_rows(payload)

    if rows.empty?
      Rails.logger.info("[MeasurementImporter] location=#{@location_id} payload had no intervals")
      return 0
    end

    Measurement.upsert_all(
      rows,
      unique_by: %i[location_id starts_at],
      record_timestamps: true
    )
  end

  private

  def build_rows(payload)
    Array(payload).flat_map do |location_data|
      Array(location_data["values"]).filter_map { |interval| row_from(interval) }
    end
  end

  def row_from(interval)
    {
      location_id: @location_id,
      starts_at:   Time.iso8601(interval["startDate"]),
      ends_at:     Time.iso8601(interval["endDate"]),
      value_kwh:   interval["value"]
    }
  rescue ArgumentError, TypeError => e
    Rails.logger.warn("[MeasurementImporter] location=#{@location_id} skipped bad interval #{interval.inspect}: #{e.message}")
    nil
  end
end
