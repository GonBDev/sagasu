class Chat < ApplicationRecord
  belongs_to :participant_one, class_name: "User"
  belongs_to :participant_two, class_name: "User"
  has_many :messages, dependent: :destroy

  scope :for_user, ->(user) { where(participant_one: user).or(where(participant_two: user)) }

  def self.between(first, second)
    one, two = [first.id, second.id].sort
    create_or_find_by!(participant_one_id: one, participant_two_id: two)
  end

  def includes_user?(user)
    participant_one_id == user.id || participant_two_id == user.id
  end

  def other_participant(user)
    participant_one_id == user.id ? participant_two : participant_one
  end

  def notes?
    participant_one_id == participant_two_id
  end
end
