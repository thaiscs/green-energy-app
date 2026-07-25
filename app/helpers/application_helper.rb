module ApplicationHelper
  def format_timeframe(timeframe)
    return "—" unless timeframe.present?

    range = "#{l(timeframe.starts_at.to_date, format: :long)} – #{l(timeframe.ends_at.to_date, format: :long)}"
    "#{range} (#{t('datetime.distance_in_words.x_days', count: timeframe.days)})"
  end
end
