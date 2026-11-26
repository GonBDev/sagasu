class Message < ApplicationRecord
  MAX_LENGTH = 5_000

  belongs_to :chat, touch: true
  belongs_to :sender, class_name: "User"
  belongs_to :task, optional: true

  validates :content, presence: true, length: { maximum: MAX_LENGTH }
  validate :sender_is_participant
  validate :task_is_assigned_to_recipient

  private

  def task_is_assigned_to_recipient
    return unless task && chat && sender
    return if !chat.notes? && chat.other_participant(sender).id == task.assignee_id

    errors.add(:task, "must be assigned to the message recipient")
  end

  def sender_is_participant
    return unless chat && sender
    return if chat.includes_user?(sender)

    errors.add(:sender, "must be a conversation participant")
  end
end
