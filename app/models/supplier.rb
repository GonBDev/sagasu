class Supplier < ApplicationRecord
  normalizes :erp_vendor_id, with: ->(value) { value.strip.presence }

  validates :name, presence: true
  validates :erp_vendor_id, uniqueness: true, allow_nil: true

  enum :size, {
    big: "big",
    mid: "mid",
    small: "small"
  }, validate: { allow_nil: true }

  def vendor_reference
    erp_vendor_id.presence || id&.to_s
  end

  has_many :reviews
end
