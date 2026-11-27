require "test_helper"

class ItemsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers # Enable sign_in for request tests.

  setup do # Start each test with its own buyer, RFQ, groups, and material.
    buyer = User.create!(email: "buyer@example.com", password: "test-password") # Create the owner before assigning the buyer grant.
    buyer.user_roles.create!(role: :buyer) # Grant the buyer access through the new table.
    @project = buyer.projects.create!(title: "Office supplies", status: :draft) # Start with an editable RFQ.
    @source_group = @project.item_groups.create!(title: "Electrical") # Create the material's starting group.
    @target_group = @project.item_groups.create!(title: "Equipment") # Create another group in the same RFQ.
    @item = @project.items.create!(description: "Cable", quantity: 2, unit_of_measure: "m", item_group: @source_group) # Add a grouped material.
    sign_in buyer # Authenticate as the owner.
  end # Finish setting up the request.

  test "buyer can move a material between groups on a draft RFQ" do # Exercise a move within one RFQ.
    move_material_to(@target_group.id) # Submit the destination group.
    assert_response :see_other # Expect the redirect after saving.
    assert_equal @target_group.id, @item.reload.item_group_id # Verify the saved assignment.
  end # Finish the draft move test.

  test "buyer can clear a material's group assignment" do # Exercise the Ungrouped option.
    move_material_to("") # Submit the blank value from the form.
    assert_response :see_other # Expect the redirect after saving.
    assert_nil @item.reload.item_group_id # Verify the material is now ungrouped.
  end # Finish the ungrouping test.

  test "buyer cannot move a material into a group from another RFQ" do # Check that assignments stay within the current RFQ.
    other_project = @project.user.projects.create!(title: "Another RFQ", status: :draft) # Give the same buyer a second RFQ.
    other_group = other_project.item_groups.create!(title: "Other group") # Create a destination outside the current RFQ.
    move_material_to(other_group.id) # Submit the out-of-project group ID.
    assert_response :not_found # Expect 404 from the project-scoped lookup.
    assert_equal @source_group.id, @item.reload.item_group_id # Verify the original assignment survived.
  end # Finish the cross-project test.

  test "buyer can move a material on a returned RFQ" do # Check that returned RFQs are editable.
    @project.update!(status: :returned) # Set up a returned RFQ.
    move_material_to(@target_group.id) # Submit the move.
    assert_response :see_other # Expect the redirect after saving.
    assert_equal @target_group.id, @item.reload.item_group_id # Verify the move was saved.
  end # Finish the returned RFQ test.

  %i[pending_approval approved].each do |status| # Run the lock check for each status.
    test "buyer cannot move a material on a #{status} RFQ" do # Exercise the locked workflow state.
      @project.update!(status: status) # Lock the RFQ for this test.
      move_material_to(@target_group.id) # Attempt the move as the owner.
      assert_response :see_other # The current access-denied handler redirects.
      assert_equal @source_group.id, @item.reload.item_group_id # Verify the redirect did not accompany a saved move.
    end # Finish the lock test for this status.
  end # Finish defining the locked-status tests.

  %i[draft returned].each do |status|
    test "buyer can delete a material on their #{status} project" do
      @project.update!(status: status)
      get bidder_list_materials_project_path(@project)
      assert_select "form[action=?][data-turbo-confirm] button[aria-label=?] .fa-trash-can",
                    project_item_path(@project, @item), "Delete Cable"

      assert_difference -> { @project.items.count }, -1 do
        delete project_item_path(@project, @item)
      end
      assert_redirected_to bidder_list_materials_project_path(@project)
      assert_not Item.exists?(@item.id)
      assert ItemGroup.exists?(@source_group.id)
    end
  end

  %i[pending_approval approved].each do |status|
    test "buyer cannot delete a material on their #{status} project" do
      @project.update!(status: status)
      get bidder_list_materials_project_path(@project)
      assert_select "button[aria-label='Delete Cable']", count: 0

      assert_no_difference -> { @project.items.count } do
        delete project_item_path(@project, @item)
      end
      assert_redirected_to project_path(@project)
    end
  end

  test "a buyer cannot delete a material from another buyer's project" do
    other_buyer = User.create!(email: "other-buyer@example.com", password: "test-password")
    other_buyer.user_roles.create!(role: :buyer)
    sign_in other_buyer

    assert_no_difference -> { @project.items.count } do
      delete project_item_path(@project, @item)
    end
    assert_response :not_found
  end

  private # Keep the request helper internal to this test class.

  def move_material_to(group_id) # Submit the same parameters as the Move material form.
    patch project_item_path(@project, @item), params: { item: { item_group_id: group_id } } # Send the nested update request.
  end # Finish the request helper.
end
