# frozen_string_literal: true

class Task < ApplicationRecord
  RESTRICTED_ATTRIBUTES = %i[title user_id]
  validates :title, presence: true, length: { maximum: 50 }
  belongs_to :user
  enum progress: { pending: 0, completed: 1 }
  enum status: { unstarred: 0, starred: 1 }
  has_many :comments, dependent: :destroy
  validates :slug, uniqueness: true
  validate :slug_not_changed

  before_create :set_slug

  # before_validation :set_title
  # validates :title, presence: true

  # def set_title
  #   self.title = "Pay electricity bill"
  # end

  private

    def set_slug
      title_slug = title.parameterize
      regex_pattern = "slug #{Constants::DB_REGEX_OPERATOR} ?"
      latest_task_slug = Task.where(
        regex_pattern,
        "#{title_slug}$|#{title_slug}-[0-9]+$"
      ).order(slug: :desc).first&.slug
      slug_count = 0
      if latest_task_slug.present?
        slug_count = latest_task_slug.split("-").last.to_i
        only_one_slug_exists = slug_count == 0
        slug_count = 1 if only_one_slug_exists
      end
      slug_candidate = slug_count.positive? ? "#{title_slug}-#{slug_count + 1}" : title_slug
      self.slug = slug_candidate
    end

    def slug_not_changed
      if slug_changed? && self.persisted?
        errors.add(:slug, t("task.slug.immutable"))
      end
    end

    def self.of_status(progress)
      if progress == :pending
        starred = pending.starred.order("updated_at DESC")
        unstarred = pending.unstarred.order("updated_at DESC")
      else
        starred = completed.starred.order("updated_at DESC")
        unstarred = completed.unstarred.order("updated_at DESC")
      end
      starred + unstarred
    end
end
