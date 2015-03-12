class BreadCrumb
  attr_accessor :title, :path

  def initialize(title, path)
    @title, @path = title, path
  end
end
