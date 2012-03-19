require 'ap'
require './attendee_cleaner'
require 'ostruct'

class Attendee
  DATEFORMAT = "%m/%d/%y %H:%M"
  attr_accessor :congressmen, :attr_array, :headers, :attr_hash

  def initialize(attributes={})
    self.attr_array = def_attrs(attributes)
    self.headers = attributes.keys
    self.attr_hash = headers.zip(attr_array)
    date_format_to_regex
  end

  def def_attrs(attributes)
    attr_array = attributes.collect do |attribute, value|
      self.singleton_class.class_eval do
        attr_accessor attribute
      end
      setter = "#{attribute}="
      clean_value = AttendeeCleaner.clean_attribute(attribute,value)
      self.send(setter, clean_value)
    end
  end

  def <=>(other)
    if other.respond_to? :regdate
      self.regdate <=> other.regdate
    else
      raise "Can't compare a #{self.class} to #{other.class}"
    end
  end

  private

  def date_format_to_regex
    format = DATEFORMAT
    format = format.gsub(/%[ymdCHIMS]/,'\\d{2}') #two digits
    format = format.gsub(/%[Y]/,'\\d{4}')    #four digits
    @date_regex = Regexp.new(format)
  end
end

module StringCleaner
  def only_digits
    self.gsub(/\D/, "")
  end
end

class String
  include StringCleaner
end

