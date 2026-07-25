class BuildingsController < ApplicationController
  def index
    @buildings = Building.includes(:units).order(:city)
  end
end
