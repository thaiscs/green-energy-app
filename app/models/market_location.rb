class MarketLocation < Location
  validates :external_id, format: { with: /\A\d{10}\z/ }
end
