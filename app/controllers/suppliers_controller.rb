class SuppliersController < ApplicationController
  after_action :verify_authorized

  def index
    authorize Supplier
    @query = params[:q].to_s.strip
    @suppliers = @query.present? ? Supplier.search_catalog(@query) : Supplier.order(:name)
  end

  def show
    @supplier = Supplier.find(params[:id])
    authorize @supplier
  end
end
