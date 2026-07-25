class Unit < ApplicationRecord
  belongs_to :building
  has_many :locations, dependent: :destroy
  has_many :measurements, through: :locations
end
