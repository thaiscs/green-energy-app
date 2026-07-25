require "test_helper"

class UnitsControllerTest < ActionDispatch::IntegrationTest
  setup do
    Measurement.delete_all
    metering = locations(:apartment_1_metering)
    market   = locations(:apartment_1_market)
    start = Time.iso8601("2026-06-01T00:00:00Z")
    metering.measurements.create!(starts_at: start, ends_at: start + 15.minutes, value_kwh: 10)
    market.measurements.create!(starts_at: start, ends_at: start + 15.minutes, value_kwh: 4)
  end

  test "shows total, average and timeframe for the consumer" do
    get unit_path(units(:apartment_1))

    assert_response :success
    assert_select "h1", "A. Beispiel"
    # Solar = 10 - 4 = 6 kWh, single day => 6 kWh/day, German-formatted "6,00".
    assert_select ".stat .value", text: /6,00/, count: 2
    assert_select ".timeframe"
  end

  test "handles a consumer with no measurements" do
    get unit_path(units(:apartment_2))

    assert_response :success
    assert_select ".empty"
  end
end
