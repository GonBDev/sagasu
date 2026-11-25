require "test_helper"

class SuppliersControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  test "directory links to supplier details and shows saved fields" do
    user = User.create!(email: "supplier-reader@example.test", password: "test-password")
    supplier = Supplier.create!(name: "Demo supplier", erp_vendor_id: "DEMO-SHOW", active: false, tags: ["rebar"])
    sign_in user

    get suppliers_path
    assert_select "a[href=?]", supplier_path(supplier), text: supplier.name

    get supplier_path(supplier)
    assert_response :success
    assert_select "h1", supplier.name
    assert_select "dd", "DEMO-SHOW"
    assert_select "dd", "Inactive"
    assert_select "dd", "rebar"
    assert_select "dd", "—"
  end

  test "supplier details require sign in" do
    supplier = Supplier.create!(name: "Demo supplier")

    get supplier_path(supplier)
    assert_redirected_to new_user_session_path
  end
end
