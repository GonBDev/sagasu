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

  test "directory search updates the results frame and can return to the full directory" do
    user = User.create!(email: "supplier-searcher@example.test", password: "test-password")
    active_supplier = Supplier.create!(name: "Steel supplier", active: true, tags: ["rebar"])
    inactive_supplier = Supplier.create!(name: "Former supplier", active: false, tags: ["rebar"])
    sign_in user

    headers = { "Turbo-Frame" => "supplier-directory-results" }
    get suppliers_path, params: { q: "rebar" }, headers: headers
    assert_response :success
    assert_select "turbo-frame#supplier-directory-results[data-turbo-action='replace']" do
      assert_select "a[href=?][data-turbo-frame='_top']", supplier_path(active_supplier), text: active_supplier.name
      assert_select "a[href=?]", supplier_path(inactive_supplier), count: 0
      assert_select "a[href=?]", suppliers_path, text: "Clear search"
    end

    get suppliers_path, headers: headers
    assert_response :success
    assert_select "turbo-frame#supplier-directory-results a[href=?]", supplier_path(inactive_supplier)
  end
end
