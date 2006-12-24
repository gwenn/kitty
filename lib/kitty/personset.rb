# Copyright (c) 2005 El Barto.
#
# Licensed under the same terms as Ruby.
require 'set'
require 'kitty/person'

module Kitty
  # Implements a Set of Persons by delegation.
  module PersonSet
    include Enumerable

    def persons
      @persons ||= Set.new
    end

    # Ensures that Group of persons are correctly merged.
    def add(persons_or_groups)
      if persons_or_groups.is_a?(Kitty::Person) # FIXME Duck Typing!
        persons.add(persons_or_groups)
      else
        persons_or_groups.each do |person_or_group|
          add(person_or_group)
        end
      end
    end
    alias :<< :add
 
    def delete(persons_or_groups)
      if persons_or_groups.is_a?(Kitty::Person) # FIXME Duck Typing!
        persons.delete(persons_or_groups)
      else
        persons_or_groups.each do |person_or_group|
          delete(person_or_group)
        end
      end
      self
    end

    def each
      persons.each do |person|
        yield(person)
      end
      self
    end
  end
end
