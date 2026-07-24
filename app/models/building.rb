class Building < ApplicationRecord
  has_many :units, dependent: :destroy
  has_many :locations, through: :units
  has_many :measurements, through: :locations
end
