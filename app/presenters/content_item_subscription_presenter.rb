class ContentItemSubscriptionPresenter
  def initialize(content_item)
    @content_item = content_item
  end

  def description
    return "This will include: #{content_item['description']}" if is_taxon?

    content_item["description"]
  end

  def child_taxons
    return unless is_taxon?

    content_item["links"]
      .fetch("child_taxons", [])
      .reject { |taxon| taxon["phase"] == "alpha" }
  end

private

  attr_accessor :content_item

  def is_taxon?
    content_item["document_type"] == "taxon"
  end
end
