# Copyright (c) 2005 El Barto.
# 
# Licensed under the same terms as Ruby.
module Kitty
  class Period # What about a Range?
    attr_reader :start, :end
  
    def initialize
      @start = 0
      @end = 0
    end

    def inc
      @end += 1
    end
    
    def to_range
      Range.new(@start, @end)
    end
  end
end
