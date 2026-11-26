require "uri"

class SupplierInvitations
  class TemplateError < StandardError; end

  PLACEHOLDERS = %w[supplier_name rfq_reference project_title material_list].freeze
  TOKEN = /\{\{([^{}]+)\}\}/
  Draft = Struct.new(:supplier_name, :email, :subject, :body, :unavailable_reason, keyword_init: true) do
    def gmail_url
      query = URI.encode_www_form(view: "cm", fs: "1", to: email, su: subject, body: body)
      "https://mail.google.com/mail/?#{query}"
    end
  end

  def initialize(version, template: nil)
    @version = version
    @template = template
  end

  def call
    subject_template, body_template = template_parts
    groups = @version.snapshot.fetch("groups")
    groups_by_supplier = {}

    groups.each do |group|
      group.fetch("suppliers").each do |supplier|
        entry = groups_by_supplier[supplier.fetch("id")] ||= { name: supplier.fetch("name"), groups: [] }
        entry.fetch(:groups) << group
      end
    end

    contacts = Supplier.where(id: groups_by_supplier.keys).index_by(&:id)
    rfq = @version.snapshot.fetch("project")
    groups_by_supplier.map do |id, entry|
      contact = contacts[id]
      email = contact&.primary_email.to_s.strip
      values = {
        "supplier_name" => entry.fetch(:name),
        "rfq_reference" => rfq["erp_rfq"].presence || "RFQ-#{@version.project_id}",
        "project_title" => rfq.fetch("title"),
        "material_list" => material_list(entry.fetch(:groups))
      }
      Draft.new(
        supplier_name: entry.fetch(:name), email: email,
        subject: substitute(subject_template, values).squish, body: substitute(body_template, values),
        unavailable_reason: unavailable_reason(contact, email, entry.fetch(:groups))
      )
    end
  end

  private

  def template_parts
    template = @template || Rails.root.join("docs/invitation_email.txt").read(encoding: "UTF-8")
    heading, body = template.split(/\r?\n/, 2)
    subject = heading&.delete_prefix("Subject:")&.strip
    unless heading&.start_with?("Subject:") && subject.present? && body.present?
      raise TemplateError, "The invitation template needs a Subject line and a message body."
    end

    fields = template.scan(TOKEN).flatten
    unless (fields - PLACEHOLDERS).empty? && body.scan(TOKEN).flatten.include?("material_list") &&
           !subject.scan(TOKEN).flatten.include?("material_list") && !template.gsub(TOKEN, "").match?(/\{\{|\}\}/)
      raise TemplateError, "The invitation template has invalid placeholders or is missing the material list."
    end

    [subject, body.strip]
  rescue SystemCallError
    raise TemplateError, "The invitation template could not be read."
  end

  def substitute(template, values)
    template.gsub(TOKEN) { values.fetch(Regexp.last_match(1)) }
  end

  def material_list(groups)
    groups.filter_map do |group|
      materials = group.fetch("materials")
      next if materials.empty?

      lines = materials.map do |material|
        "- #{material.fetch('description')} (#{material.fetch('quantity')} #{material.fetch('unit_of_measure')})"
      end
      [group.fetch("title"), *lines].join("\n")
    end.join("\n\n")
  end

  def unavailable_reason(contact, email, groups)
    return "Supplier record is unavailable." unless contact
    return "Supplier is inactive." unless contact.active?
    return "Supplier has no usable email address." unless email.match?(URI::MailTo::EMAIL_REGEXP) && !email.match?(/[\r\n,;?&#]/)
    return "No materials were approved for this supplier." if groups.all? { |group| group.fetch("materials").empty? }
  end
end
