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

  def self.search_catalog(query)
    pattern = "%#{sanitize_sql_like(query)}%"
    where(active: true).where(<<~SQL, pattern: pattern).order(:name, :id)
      suppliers.name ILIKE :pattern OR suppliers.category ILIKE :pattern OR EXISTS (
        SELECT 1 FROM unnest(suppliers.tags) AS catalog_tag(value)
        WHERE catalog_tag.value ILIKE :pattern
      )
    SQL
  end
end
