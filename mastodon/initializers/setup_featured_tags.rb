# frozen_string_literal: true

# Épingle les hashtags de matière sur le compte admin au démarrage.
# Idempotent — ne recrée pas les tags déjà existants.

FEATURED_HASHTAGS = %w[
  Maths Informatique Physique Chimie Electronique
  Reseaux Programmation Hénallux Tutorat Annonces
].freeze

Rails.application.config.after_initialize do
  next unless Rails.env.production?

  Rails.application.executor.wrap do
    begin
      admin = Account.local.joins(:user)
                     .merge(User.where(role_id: UserRole.where(name: 'Admin').select(:id)))
                     .first
      next unless admin

      existing = FeaturedTag.where(account: admin).pluck(:name).map(&:downcase).to_set

      FEATURED_HASHTAGS.each do |tag|
        next if existing.include?(tag.downcase)

        tag_record = Tag.find_or_create_by!(name: Tag.normalize(tag))
        FeaturedTag.find_or_create_by!(account: admin, tag: tag_record)
        Rails.logger.info("[setup_featured_tags] Hashtag ##{tag} épinglé sur @#{admin.username}")
      end
    rescue => e
      Rails.logger.warn("[setup_featured_tags] Erreur : #{e.message}")
    end
  end
end
