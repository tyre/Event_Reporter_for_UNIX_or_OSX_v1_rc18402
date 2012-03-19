require "./SNode"
class Stack
  include Comparable
  attr_reader :top, :size
  def initialize()
    @top = nil
    @size = 0
  end

  def push(data)
    node = SNode.new(data)
    node.next = @top
    @top = node
    @size += 1
  end

  def pop
    if @top
      @top = top.next
      @size-=1
    end
  end

  def <=>(other)
    self.size <=> other.size
  end

  def empty?
    !self.top.nil?
  end

  def empty
    while (not empty?)
      pop
    end
  end

  def to_s
    if @top
      temp = @top
      while temp
        puts temp.value
        temp = temp.next
      end
    else
      puts "The stack is empty"
    end
  end
end