# Copyright (c) 2005 El Barto.
# 
# Licensed under the same terms as Ruby.
require 'kitty/personset'

module Kitty
  # A sub-group of persons making common expenses.
  #--
  class Group
    attr_reader :name
    include PersonSet

    def initialize(name)
      raise(ArgumentError, 'Illegal nil or empty name', caller) if name.nil? || name.empty?
      @name = name
    end
  end
end
