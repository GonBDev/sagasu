class ProjectPolicy < ApplicationPolicy
  # NOTE: Up to Pundit v2.3.1, the inheritance was declared as
  # `Scope < Scope` rather than `Scope < ApplicationPolicy::Scope`.
  # In most cases the behavior will be identical, but if updating existing
  # code, beware of possible changes to the ancestors:
  # https://gist.github.com/Burgestrand/4b4bc22f31c8a95c425fc0e30d7ef1f5

  class Scope < ApplicationPolicy::Scope
    # NOTE: Be explicit about which records you allow access to!
    # def resolve
    #   scope.all
    # end
    def resolve
      return scope.all if user.has_role?(:viewer) || user.has_role?(:auditor) # Let viewers and auditors list all RFQs.

      scope.where(user_id: user.id) # Limit everyone else to their own RFQs.
    end
  end

  def create?
    user.has_role?(:buyer) # Require a buyer grant to create RFQs.
  end

  def show?
    record.user_id == user.id || user.has_role?(:viewer) || user.has_role?(:auditor) # Allow owners, viewers, and auditors to open RFQs.
  end

  def add_material?
    editable_by_owner? # Apply the shared edit rule when adding materials.
  end

  def edit_material?
    editable_by_owner? # Apply the same rule when updating or moving materials.
  end

  def manage_item_groups? # Authorize creating, renaming, and deleting groups.
    editable_by_owner? # Apply the same rule to group changes.
  end # End the group management policy.

  private # Keep the shared authorization helper internal.

  def editable_by_owner? # Centralize authorization for project edits.
    user.has_role?(:buyer) && record.user_id == user.id && (record.draft? || record.returned?) # Require ownership even when the buyer also has organization-wide read access.
  end # End the shared authorization helper.
end
