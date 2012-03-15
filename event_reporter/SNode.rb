class SNode #a singley link node
  attr_accessor :next, :value
  def initialize(value, n=nil)
    @value = value
    @next=n
  end
end