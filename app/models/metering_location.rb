class MeteringLocation < Location
  validates :external_id,
    format: { with: /\A[A-Z0-9]{33}\z/,
              message: "must be 33 alphanumeric characters" },
    allow_blank: true
end
