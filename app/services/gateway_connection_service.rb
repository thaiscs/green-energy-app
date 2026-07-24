# The response is an array of location objects, each carrying a `values`
# array of 15-minute intervals shaped like:
#
#   { "value" => 1.4788, "quality" => "TRUE",
#     "startDate" => "2026-06-04T00:15:00+02:00",
#     "endDate"   => "2026-06-04T00:30:00+02:00" }
#
class GatewayConnectionService
  class Error < StandardError; end

  BASE_URL = ENV.fetch(
    "MEASUREMENT_API_URL",
    "https://mock-measurement-api-8fbe027730b7.herokuapp.com"
  ).freeze

  def initialize(connection: nil)
    @connection = connection || build_connection
  end

  def fetch_data(location_id, begin_date:)
    response = @connection.get("/values/#{location_id}/load-profile") do |req|
      req.params["beginDate"] = begin_date.to_s
    end

    unless response.success?
      raise Error, "request for #{location_id} failed: HTTP #{response.status}"
    end

    Array(response.body)
  rescue Faraday::Error => e
    raise Error, "request for #{location_id} failed: #{e.message}"
  end

  private

  def build_connection
    Faraday.new(url: BASE_URL) do |f|
      f.request :url_encoded
      f.response :json
      f.options.timeout      = 30
      f.options.open_timeout = 10
      f.adapter Faraday.default_adapter
    end
  end
end
