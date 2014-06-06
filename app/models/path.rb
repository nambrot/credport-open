class Path
  attr_accessor :path
  def initialize(path)
    self.path = path
  end
  
  def length
    (self.path.length - 1) / 2
  end
  
  def start
    self.path.first
  end
  
  def end
    self.path.last
  end
  
  def nodes
    self.path.select.with_index{|_,i| (i+1) % 2 != 0}
  end
  
  def connections
    self.path.select.with_index{|_,i| (i+1) % 2 == 0}
  end
  
end