class ImportConsumptionDataDispatcherJob < ApplicationJob
  queue_as :default

  DEFAULT_BEGIN_DATE = "2026-06-04" # or Date.yesterday.to_s for daily runs

  def perform(begin_date = DEFAULT_BEGIN_DATE)
    enqueue(MarketLocation, begin_date)
    enqueue(MeteringLocation, begin_date)
  end

  private

  def enqueue(location_class, begin_date)
    jobs = location_class.where.not(external_id: nil)
                         .pluck(:external_id, :id)
                         .map { |external_id, id| ImportLocationDataJob.new(external_id, id, begin_date) }

    ActiveJob.perform_all_later(jobs) # single bulk enqueue, not one round-trip per job
  end
end
