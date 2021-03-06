require File.expand_path(File.join(File.dirname(__FILE__), 'spec_helper'))

describe JsonRecord::EmbeddedDocument do
    
  it "should have a schema" do
    JsonRecord::Test::Trait.schema.should_not == nil
  end
  
  it "should have a parent object" do
    trait = JsonRecord::Test::Trait.new(:name => "n1", :value => "v1")
    trait.parent.should == nil
    trait.parent = :parent
    trait.parent.should == :parent
  end
  
  it "should have attributes" do
    trait = JsonRecord::Test::Trait.new(:name => "n1", :value => "v1")
    trait.name.should == "n1"
    trait.value.should == "v1"
    trait.attributes.should == {"name" => "n1", "value" => "v1"}
    trait.name = "n2"
    trait.value = "v2"
    trait.name.should == "n2"
    trait.value.should == "v2"
    trait.attributes.should == {"name" => "n2", "value" => "v2"}
  end
  
  it "should have attributes before type cast" do
    trait = JsonRecord::Test::Trait.new
    trait.name = 1
    trait.count = "12"
    trait.name_before_type_cast.should == 1
    trait.count_before_type_cast.should == "12"
    trait.name.should == "1"
    trait.count.should == 12
  end
  
  it "should track changes to attributes" do
    trait = JsonRecord::Test::Trait.new(:value => "val")
    trait.value_changed?.should == true
    trait.value_was.should == nil
    trait.value_change.should == [nil, "val"]
    trait.name = "test"
    trait.name_was.should == nil
    trait.name_changed?.should == true
    trait.name_change.should == [nil, "test"]
    trait.changes.should == {"value" => [nil, "val"], "name" => [nil, "test"]}
    trait.name = nil
    trait.name_changed?.should == false
    trait.name_was.should == nil
    trait.name_change.should == nil
    trait.changes.should == {"value" => [nil, "val"]}
  end
  
  it "should convert to attributes to json" do
    trait = JsonRecord::Test::Trait.new(:name => "n1", :value => "v1")
    ActiveSupport::JSON.decode(trait.to_json).should == {"name" => "n1", "value" => "v1"}
  end
  
  it "should consider it equal to another EmbeddedDocument with the same attributes and parent" do
    trait_1 = JsonRecord::Test::Trait.new(:name => "n1", :value => "v1")
    trait_2 = JsonRecord::Test::Trait.new(:name => "n1", :value => "v1")
    (trait_1 == trait_2).should == true
    trait_1.eql?(trait_2).should == true
    (trait_1.hash == trait_2.hash).should == true
  end
  
  it "should read json attributes with []" do
    dimension = JsonRecord::Test::Dimension.new(:width => 100)
    dimension[:width].should == 100
  end
  
  it "should be able to write json attributes with []=" do
    dimension = JsonRecord::Test::Dimension.new
    dimension[:width] = 100
    dimension.width.should == 100
  end
  
  it "should set all accessors on initialize" do
    dimension = JsonRecord::Test::Dimension.new(:width => 100, :height => :infinity, :unit => "meters")
    dimension.width.should == 100
    dimension.height.should == 1000000000
    dimension.unit.should == "meters"
  end
  
end
