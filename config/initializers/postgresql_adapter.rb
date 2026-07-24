# Store timestamps as `timestamptz` (timezone-aware) instead of the default
# `timestamp` (without time zone). Applied via the load hook so it runs only
# once the PostgreSQL adapter is loaded, avoiding premature adapter loading.
ActiveSupport.on_load(:active_record_postgresqladapter) do
  self.datetime_type = :timestamptz
end
