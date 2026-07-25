class UnitsController < ApplicationController
  def show
    @unit = Unit.find(params[:id])
    @report = SolarConsumptionReport.new(@unit).call
  end
end
