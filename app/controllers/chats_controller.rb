class ChatsController < ApplicationController
  before_action :load_inbox, only: %i[index show]

  def index
    @pending_approvals = if current_user.has_role?(:approver)
      current_user.approvals.pending.joins(:project).where(projects: { status: :pending_approval })
                  .where.not(bidder_list_version_id: nil).includes(:bidder_list_version).order(:created_at, :id)
    else
      Approval.none
    end
    @returned_projects = current_user.has_role?(:buyer) ? current_user.projects.returned.order(updated_at: :desc) : Project.none
  end

  def show
    @chat = Chat.for_user(current_user).find(params[:id])
    @messages = @chat.messages.includes(:sender, task: :actionable).order(:created_at, :id).to_a
    incoming_ids = @messages.reject { |message| message.sender_id == current_user.id }.map(&:id)

    @chat.messages.where(id: incoming_ids, read_at: nil).update_all(read_at: Time.current)
    @unread_counts.delete(@chat.id)
  end

  def create
    email = params[:recipient_email].to_s.strip.downcase
    recipient = email.present? && User.find_by(email: email)
    unless recipient
      return redirect_to messages_path, alert: "No account matches that email address.", status: :see_other
    end

    redirect_to chat_path(Chat.between(current_user, recipient)), status: :see_other
  end

  def notes
    redirect_to chat_path(Chat.between(current_user, current_user)), status: :see_other
  end

  private

  def load_inbox
    @chats = Chat.for_user(current_user).includes(:participant_one, :participant_two).order(updated_at: :desc, id: :desc)
    @unread_counts = Message.where(chat_id: Chat.for_user(current_user).select(:id), read_at: nil)
                            .where.not(sender: current_user).group(:chat_id).count
  end
end
