class TestBase
  cattr_accessor :columns_hash, :after_save_called_with, :after_destroy_called_with, :callbacks
  attr_accessor :attributes
  
  def self.attributes(attrs = {})
    self.callbacks = {}
    type_struct = Struct.new(:type)
    self.columns_hash = {}
    attrs.each do |attr, type|
      columns_hash[attr.to_s] = type_struct.new(type)
    end
    
    class_eval do
      attrs.each do |attr, type|
        attr_accessor attr
      end
    end
  end
  
  def initialize(attrs = {})
    @attributes = attrs
  end
  
  def self.after_save(name)
    callbacks[name] = true
  end
  
  def self.after_destroy(name)
    callbacks[name] = true
  end
  
  def self.column_names
    columns_hash.collect {|key, value| key}
  end
  
  def [](key)
    attributes[key]
  end
end

class Test::User < TestBase
  attributes :birthdate => :date
end