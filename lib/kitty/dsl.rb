# Copyright (c) 2005 El Barto.
# 
# Licensed under the same terms as Ruby.
require 'kitty/group'
require 'kitty/person'
require 'kitty/trip'

module Kitty
  module DSL
    #def DSL.extended(obj) FIXME
    #end

    # Declares the current Trip.
    # 
    # <b>+name+ must be capitalized</b>.
    def trip(name, *persons)
      trip = singleton_class.const_set(name, Kitty::Trip.new(name))
      singleton_class.const_set(:TRIP, trip)
      persons.each do |person|
        trip << create_person(person)
      end
      trip
    end
    
    # Declares one Person taking part in the current trip.
    # 
    # <b>+name+ must be capitalized</b>.
    def person(name)
      person = singleton_class.const_set(name, Kitty::Person.new(name))
      current_trip << person
      person
    end
    
    # Declares a sub-group of persons. This is useful when these persons have many expenses in common.
    #
    # <b>+name+ must be capitalized</b>.
    def group(name, *persons)
      group = singleton_class.const_set(name, Kitty::Group.new(name))
      persons.each do |person|
        if person.is_a?(Kitty::Person)
          group << person
        else
          group << create_person(person)
        end
      end
      current_trip << group
      group
    end

    # Calculates credit and debit balances and then suggests optimal repayments.
    def balance
      current_trip.balance()
    end
    alias :checkout :balance

    private
    def create_person(name)
      singleton_class.const_set(name, Kitty::Person.new(name))
    end
    
    def current_trip
      unless singleton_class.const_defined?(:TRIP)
        warn('No trip defines! A default one is created.')
        trip('One trip')
      end
      singleton_class.const_get(:TRIP)
    end

    # http://www.whytheluckystiff.net/articles/seeingMetaclassesClearly.html
    def singleton_class
      class << self
        self
      end
    end
  end

  # Context in which DSL instructions are interpreted.
  class Trick
    include DSL

    def Trick.const_missing(sym)
      warn("Constante '%s' was not declared! The corresponding person is created." % sym)
      # FIXME duplication of person(sym) in DSL
      person = const_set(sym, Kitty::Person.new(sym.to_s))
      unless const_defined?(:TRIP)
        const_set(:TRIP, Kitty::Trip.new('One trip'))
      end
      const_get(:TRIP) << person
      person
    end
  end
end
