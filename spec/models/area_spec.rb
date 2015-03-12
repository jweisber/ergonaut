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

require 'spec_helper'

describe Area do  
  let(:area) { FactoryGirl.create(:area) }  
  subject { area }
  
  
  # valid factory
  
  it { should be_valid }
  
  
  # attributes
  
  it { should respond_to(:name) }
  it { should respond_to(:short_name) }
  it { should respond_to(:removed) }
  
  
  # validations
  
  it "is not valid without a name" do
    area.name = nil
    area.should_not be_valid
  end
  
  it "is not valid when name is taken" do
    area_with_same_name = FactoryGirl.create(:area)
    area_with_same_name.name = area.name
    area_with_same_name.should_not be_valid
  end
  
  it "is not valid without a short name" do
    area.short_name = nil
    area.should_not be_valid
  end
  
  it "is not valid when short name is taken" do
    area_with_same_short_name = FactoryGirl.create(:area)
    area_with_same_short_name.short_name = area.short_name
    area_with_same_short_name.should_not be_valid
  end
  
  it "is not valid when short name is more than 12 chars" do
    area.short_name = "a" * 13
    area.should_not be_valid
  end
  
  
  # defaults
  
  it "sets removed to false by default" do
    expect(area.removed).to eq(false)
  end
  
  
  # instance methods

  describe "#active_ordered_by_name" do
    before(:all) do
      Area.delete_all
      25.times { FactoryGirl.create(:area) }
      5.times { FactoryGirl.create(:removed_area) }
    end
    after(:all) { Area.delete_all }
    
    it "returns the active areas only" do
      Area.active_ordered_by_name.should have(25).items
    end
    
    it "returns areas sorted by name" do
      sorted_names = Area.active_ordered_by_name.pluck(:name).sort
      expect(Area.active_ordered_by_name.pluck(:name)).to eq(sorted_names)
    end
  end
  
end
