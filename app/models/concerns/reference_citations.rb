# frozen_string_literal: true

# Reference Citations
module ReferenceCitations
  extend ActiveSupport::Concern
  included do
  end

  def set_citation!
    json = citation_json
    self.citation_html = json["result"]["citationHtml"]
    self.citation = json["result"]["citation"]
    save!
  end

  def citation_json
    resource = Reference::AsServices.citation_strings_url(id)
    JSON.load(open(resource))
  rescue => e
    logger.error("Exception rescued in ReferencesController#citation_json!")
    logger.error(e.to_s)
    logger.error("Check resource: #{resource}")
  end
end
