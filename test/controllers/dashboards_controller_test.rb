require "test_helper"

class DashboardsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  test "guests see Home and signed-in users land on Dashboard with Dashboard first in navigation" do
    get root_path
    assert_response :success
    assert_select "#home-title"
    get dashboard_path
    assert_redirected_to new_user_session_path

    sign_in account("dashboard-base")
    get root_path
    assert_redirected_to dashboard_path
    follow_redirect!
    assert_select "nav[aria-label='Main navigation'] .navbar-nav > li:first-child a", text: "Dashboard"
    assert_select "a[href=?]", dashboard_path(anchor: "quick-start"), text: "Quick Start"
    assert_select "main a[href=?]", new_project_path, count: 0
  end

  test "buyer sees only accessible project counts, returned tasks, and incoming unread messages" do
    buyer = account("dashboard-buyer", :buyer)
    other = account("dashboard-other", :buyer)
    viewer = account("dashboard-auditor", :auditor)
    own = buyer.projects.create!(title: "Own returned RFQ", status: :returned)
    buyer.projects.create!(title: "Own draft RFQ")
    other.projects.create!(title: "Private approval RFQ", status: :pending_approval)
    group = own.item_groups.create!(title: "Steel")
    own.items.create!(item_group: group, description: "Steel", quantity: 4, unit_of_measure: "kg")
    supplier = Supplier.create!(name: "Steel maker")
    GroupSupplier.create!(item_group: group, supplier: supplier, selected: true, source: :search)
    chat = Chat.between(buyer, other)
    chat.messages.create!(sender: other, content: "Incoming")
    chat.messages.create!(sender: buyer, content: "Outgoing")
    Chat.between(viewer, other).messages.create!(sender: other, content: "Other unread")

    sign_in buyer
    get dashboard_path
    assert_response :success
    assert_select "section[aria-label='Dashboard summary'] p.h2" do |counts|
      assert_equal %w[2 1 0 1], counts.map { |count| count.text.strip }
    end
    assert_select "#quick-start a", text: "Own returned RFQ"
    assert_select "article h3", text: "Private approval RFQ", count: 0
    assert_select "article progress[value='1'][max='1']"
    assert_select "main a[href=?]", new_project_path, text: /New RFQ project/
    get dashboard_path, params: { status: "returned" }
    assert_select "article h3", text: "Own returned RFQ"
    assert_select "article h3", text: "Own draft RFQ", count: 0

    sign_in viewer
    get dashboard_path
    assert_select "article h3", text: "Private approval RFQ"
    assert_select "#quick-start a", text: "Own returned RFQ", count: 0
    assert_select "main a[href=?]", new_project_path, count: 0
  end

  test "assigned approver sees a task without seeing the buyer's project grid" do
    buyer = account("dashboard-task-buyer", :buyer)
    reviewer = account("dashboard-reviewer", :approver)
    other = account("dashboard-other-reviewer", :approver)
    project = buyer.projects.create!(title: "Assigned review", status: :pending_approval)
    version = project.bidder_list_versions.create!(created_by: buyer, version_number: 1,
                                                   snapshot: BidderListSnapshot.for_project(project))
    project.approvals.create!(approver: reviewer, bidder_list_version: version)

    sign_in reviewer
    get dashboard_path
    assert_select "#quick-start a[href=?]", bidder_list_approval_project_path(project), text: "Assigned review"
    assert_select "article h3", text: "Assigned review", count: 0
    assert_select "main a[href=?]", new_project_path, count: 0

    sign_in other
    get dashboard_path
    assert_select "#quick-start a", text: "Assigned review", count: 0
  end

  private

  def account(name, role = :base)
    User.create!(email: "#{name}@example.test", password: "test-password").tap do |user|
      user.user_roles.create!(role: role)
    end
  end
end
