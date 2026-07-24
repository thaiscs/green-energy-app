class Location < ApplicationRecord
  belongs_to :unit
  has_one :building, through: :unit
  has_many :measurements, dependent: :delete_all

  validates :external_id, presence: true
end
