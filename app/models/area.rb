# == Schema Information
#
# Table name: areas
#
#  id         :integer          not null, primary key
#  name       :string(255)
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  short_name :string(255)
#  removed    :boolean
#

class Area < ActiveRecord::Base
  has_many :submissions
  has_many :editors, class_name: 'User', foreign_key: :editor_area_id
  before_create :set_defaults
  
  validates :name, presence: true, length: { minimum: 1 }, uniqueness: true
  validates :short_name, presence: true, length: { minimum: 1, maximum: 12 }, uniqueness: true
  
  def self.active_ordered_by_name
    areas = Area.where(removed: false)
    areas.sort! do |a, b|
      unless a.name == 'Not Listed' || b.name == 'Not Listed'
        a.name <=> b.name
      else
        a.name == 'Not Listed' ? 1 : -1
      end
    end
  end
  
  private 
  
    def set_defaults
      self.removed = false if self.removed.nil?
      return true
    end
end
