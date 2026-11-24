class SuppliersController < ApplicationController
  after_action :verify_authorized

  def index
    authorize Supplier
    @suppliers = Supplier.order(:name)
  end
end
