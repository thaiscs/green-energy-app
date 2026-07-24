class ImportLocationDataJob < ApplicationJob
  queue_as :default

  # Transient API failures: back off and retry. Safe because the upsert is
  # idempotent, so a retry can't create duplicate rows.
  retry_on GatewayConnectionService::Error, wait: :polynomially_longer, attempts: 5

  # Location deleted between dispatch and execution -> the FK no longer exists,
  # so the upsert can never succeed. Drop the job instead of retrying.
  discard_on ActiveRecord::InvalidForeignKey

  def perform(external_id, location_id, begin_date)
    payload = GatewayConnectionService.new.fetch_data(external_id, begin_date: begin_date)
    count = MeasurementImporter.new(location_id).call(payload)
    Rails.logger.info("[ImportLocationDataJob] location=#{location_id} imported #{count} measurements")
  end
end
