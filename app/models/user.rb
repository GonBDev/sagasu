class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  enum :role, {
    buyer: "buyer",
    approver: "approver",
    viewer: "viewer"
  }, validate: true

  has_many :projects
  has_many :approvals, foreign_key: :approver_id, inverse_of: :approver
  has_many :reviews
end
