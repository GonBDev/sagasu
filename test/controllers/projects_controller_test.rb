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

  test "project index combines title search with status and counts only visible matches" do
    owner = @project.user
    approved = owner.projects.create!(title: "Warehouse roofing", status: :approved)
    owner.projects.create!(title: "Office lighting", status: :approved)
    @reader.projects.create!(title: "Warehouse drainage", status: :approved)
    @item.update!(item_group: @group)
    sign_in owner

    get projects_path, params: { q: "warehouse", status: "draft" }
    assert_response :success
    assert_select "article h2 a", text: @project.title
    assert_select "article progress[value='1'][max='1']"
    assert_select "article h2 a", text: approved.title, count: 0
    assert_select "nav[aria-label='Filter projects by status'] a[href=?] .badge",
                  projects_path(status: "approved", q: "warehouse"), text: "1"

    get projects_path, params: { q: "warehouse", status: "approved" }
    assert_select "article h2 a", text: approved.title
    assert_select "article h2 a", count: 1
    assert_select "form[role='search'] input[name='status'][value='approved']"
  end

  test "approval summary counts groups in the saved or submitted bidder list" do
    owner = @project.user
    owner.user_roles.create!(role: :buyer)
    @reader.user_roles.create!(role: :approver)
    other_group = @project.item_groups.create!(title: "Lighting")
    supplier = Supplier.create!(name: "Supplier A", active: true)
    [@group, other_group].each do |group|
      GroupSupplier.create!(item_group: group, supplier: supplier, source: :search, selected: true)
    end
    version = @project.bidder_list_versions.create!(created_by: owner, version_number: 1,
                                                    snapshot: BidderListSnapshot.for_project(@project))
    GroupSupplier.find_by!(item_group: other_group, supplier: supplier).update!(selected: false)

    sign_in owner
    get bidder_list_approval_project_path(@project)
    assert_select "aside[aria-labelledby='bidder-list-summary-title'] dl" do
      assert_select "dt", text: supplier.name, count: 1
      assert_select "dd", text: "2 groups"
    end

    @project.bidder_list_versions.create!(created_by: owner, version_number: 2,
                                         snapshot: BidderListSnapshot.for_project(@project))
    @project.approvals.create!(approver: @reader, bidder_list_version: version)
    @project.pending_approval!
    sign_in @reader

    get bidder_list_approval_project_path(@project)
    assert_response :success
    assert_select "aside[aria-labelledby='bidder-list-summary-title']" do
      assert_select "p", text: "Version 1"
      assert_select "dd", text: "2 groups"
    end
  end

  test "buyer can create the first group from the manage groups card" do
    owner = @project.user
    owner.user_roles.create!(role: :buyer)
    @group.destroy!
    sign_in owner

    get bidder_list_groups_project_path(@project)
    assert_select "section[aria-labelledby='manage-groups-title']" do
      assert_select "button[data-bs-target='#new-group-panel']", text: "New group"
      assert_select "#new-group-panel.collapse form[action=?]", project_item_groups_path(@project)
    end
    assert_difference -> { @project.item_groups.count }, 1 do
      post project_item_groups_path(@project), params: { item_group: { title: "First group" } }
    end
    assert_redirected_to bidder_list_groups_project_path(@project)
  end

  test "group management rows keep rename and delete scoped to the chosen group" do
    owner = @project.user
    owner.user_roles.create!(role: :buyer)
    other_group = @project.item_groups.create!(title: "Lighting")
    @item.update!(item_group: @group)
    sign_in owner

    get bidder_list_groups_project_path(@project)
    path = project_item_group_path(@project, @group)
    panel = ActionView::RecordIdentifier.dom_id(@group, :rename)
    assert_select "section[aria-labelledby='manage-groups-title']" do
      assert_select "button[data-bs-target=?] .fa-pen", "##{panel}"
      assert_select "div[id=?].collapse form[action=?] input[name='item_group[title]']", panel, path
      assert_select "form[action=?][data-turbo-confirm] button .fa-trash-can", path
    end

    patch path, params: { item_group: { title: "Cabling" } }
    assert_redirected_to bidder_list_groups_project_path(@project)
    assert_equal "Cabling", @group.reload.title

    delete path
    assert_redirected_to bidder_list_groups_project_path(@project)
    assert_nil @item.reload.item_group_id
    assert ItemGroup.exists?(other_group.id)
  end

  test "group summary lists materials under their assigned group" do
    @item.update!(item_group: @group)
    @project.items.create!(description: "Ungrouped material", quantity: 1, unit_of_measure: "each")
    @project.item_groups.create!(title: "Empty group")
    sign_in @project.user

    get bidder_list_groups_project_path(@project)
    assert_response :success
    assert_select "aside[aria-labelledby='group-summary-title']" do
      assert_select "details[open] summary span[title=?]", @group.title, text: @group.title
      assert_select "details ul li", text: @item.description
      assert_select "details ul li", text: "Ungrouped material", count: 0
      assert_select "details p", text: "No materials in this group."
    end
  end

  test "supplier group count follows the draft shortlist" do
    owner = @project.user
    owner.user_roles.create!(role: :buyer)
    @item.update!(item_group: @group)
    supplier = Supplier.create!(name: "Kisaragi Doors & Hardware Materials", active: true)
    GroupSupplier.create!(item_group: @group, supplier: supplier, source: :search, selected: true)
    sign_in owner

    get bidder_list_suppliers_project_path(@project)
    assert_select "p", text: /1 material\s*·\s*1 supplier/
    assert_select "aside[aria-labelledby='draft-bidder-list-title'] a[title=?]", supplier.name, text: supplier.name
    assert_select "aside button[aria-label=?] .fa-trash-can", "Remove #{supplier.name} from #{@group.title}"

    patch shortlist_supplier_project_item_group_path(@project, @group), params: { supplier_id: supplier.id, selected: "false" }
    follow_redirect!
    assert_select "p", text: /1 material\s*·\s*0 suppliers/
  end

  test "bulk AI supplier suggestions require materials in an editable project group" do
    owner = @project.user
    owner.user_roles.create!(role: :buyer)
    sign_in owner
    workspace = bidder_list_suppliers_project_path(@project)
    bulk_action = suggest_suppliers_for_all_project_item_groups_path(@project)

    get workspace
    assert_select "form[action=?]", bulk_action, count: 0
    post bulk_action
    assert_redirected_to workspace
    assert_equal "Add materials to a group before suggesting suppliers.", flash[:alert]

    post suggest_suppliers_project_item_group_path(@project, @group), headers: { "Accept" => "text/vnd.turbo-stream.html" }
    assert_response :success
    assert_select "turbo-stream[action='refresh'][method='morph'][scroll='preserve']"
    assert_equal "Add materials to this group before suggesting suppliers.", flash[:alert]

    @item.update!(item_group: @group)
    get workspace
    assert_select "header form[action=?] .fa-wand-magic-sparkles", bulk_action

    @project.approved!
    get workspace
    assert_select "form[action=?]", bulk_action, count: 0
    assert_no_difference -> { AiRun.count } do
      assert_raises(Pundit::NotAuthorizedError) { post bulk_action }
    end
  end

  test "owning buyer can edit project information on draft and returned RFQs" do
    owner = @project.user
    owner.user_roles.create!(role: :buyer)
    sign_in owner

    get new_project_path
    assert_select "select[name='project[budget_currency]'] option[value]" do |options|
      assert_equal ["", "JPY", "USD", "EUR", "MXN", "PEN", "CFP"], options.map { |option| option["value"] }
    end

    get project_path(@project)
    assert_select "a[href=?] i.fas.fa-pen", edit_project_path(@project)
    @project.update!(budget_currency: "CAD")
    get edit_project_path(@project)
    assert_response :success
    assert_select "input[type='text'][name='project[title]'][value=?]", @project.title
    assert_select "select[name='project[budget_currency]'] option[value='CAD'][selected]"

    patch project_path(@project), params: { project: { title: "", scope: "New scope" } }
    assert_response 422
    assert_equal "Warehouse lighting", @project.reload.title

    @project.returned!
    patch project_path(@project), params: { project: { title: "Updated RFQ", scope: "New scope", status: "approved" } }
    assert_redirected_to project_path(@project)
    assert_equal "Updated RFQ", @project.reload.title
    assert_equal "New scope", @project.scope
    assert @project.returned?
  end

  test "approved RFQs and other owners' RFQs cannot be edited" do
    owner = @project.user
    owner.user_roles.create!(role: :buyer)
    @project.approved!
    sign_in owner

    get project_path(@project)
    assert_select "a[href=?]", edit_project_path(@project), count: 0
    patch project_path(@project), params: { project: { title: "Blocked" } }
    assert_redirected_to root_path
    assert_equal "Warehouse lighting", @project.reload.title

    @reader.user_roles.create!(role: :auditor)
    sign_in @reader
    get edit_project_path(@project)
    assert_response :not_found
  end
end
