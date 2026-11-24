require "test_helper"

class ProjectsControllerTest < ActionDispatch::IntegrationTest
include Devise::Test::IntegrationHelpers # Sign in as each account during request tests.

setup do # Create an RFQ owned by a different account.
  owner = User.create!(email: "rfq-owner@example.test", password: "test-password") # Create the RFQ owner.
  @project = owner.projects.create!(title: "Warehouse lighting") # Create the RFQ we'll try to open.
  @item = @project.items.create!(description: "Cable", quantity: 2, unit_of_measure: "m") # Add an ungrouped material.
  @group = @project.item_groups.create!(title: "Electrical") # Create a destination for the attempted move.
  @reader = User.create!(email: "rfq-reader@example.test", password: "test-password") # Create the account exercising access.
  @reader.user_roles.create!(role: :base) # Give the reader the same starting grant as public signup.
end # Finish preparing the test records.

%i[viewer auditor].each do |role| # Verify both organization-wide read grants.
  test "#{role} can list and open another buyer's RFQ" do # Exercise both the index and detail routes.
    @reader.user_roles.create!(role: role) # Add the read grant being tested.
    sign_in @reader # Authenticate as the reader.
    get projects_path # Open the RFQ list.
    assert_response :success # Verify the list loads.
    assert_includes response.body, @project.title # Verify the other account's RFQ is listed.
    get project_path(@project) # Open the RFQ directly.
    assert_response :success # Verify the detail page loads.
  end # Finish the read access test.
end # Finish defining both role tests.

test "base cannot open another buyer's RFQ" do # Verify the default signup grant stays restricted.
  sign_in @reader # Use the account with only BASE.
  get project_path(@project) # Request another account's RFQ directly.
  assert_response :not_found # Verify the project lookup excludes it.
end # Finish the BASE access test.

test "buyer with viewer access cannot move another buyer's material" do # Check that broader read access preserves write boundaries.
  @reader.user_roles.create!(role: :buyer) # Grant buying permissions on owned RFQs.
  @reader.user_roles.create!(role: :viewer) # Grant read access to this RFQ.
  sign_in @reader # Authenticate with both grants.
  patch project_item_path(@project, @item), params: { item: { item_group_id: @group.id } } # Attempt a move on the other account's RFQ.
  assert_response :not_found # Verify the write lookup excludes the RFQ.
  assert_nil @item.reload.item_group_id # Verify the material stayed ungrouped.
end # Finish the cross-owner write test.
end
