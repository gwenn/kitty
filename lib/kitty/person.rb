# Copyright (c) 2005 El Barto.
# 
# Licensed under the same terms as Ruby.
require 'kitty/payment'

module Kitty
  # A person taking part in a Trip.
  class Person
    attr_reader :name
    attr_reader :pay_back_persons

    def initialize(name)
      raise(ArgumentError, 'Illegal nil or empty name', caller) if name.nil? || name.empty?
      @name = name
    end

    # Returns the expenses made by this person.
    def payments
      @payments ||= []
    end

    # Adds one expense.
    def pay(amount, desc = 'stuff')
      payments << Payment.new(self, amount, desc)
      self
    end
    alias :spend :pay
 
    def lend(amount, purpose, *persons)
      payments << Payment.new(self, amount, { :purpose => purpose,
                              :exclude => self, :include => persons })
      self
    end

    # Changes the way repayments are divided up.
    #--
    # FIXME destructive method
    def prefer_to_pay_back(*persons)
      @pay_back_persons = persons
    end

    # +Visitor+ pattern : _Element_
    def accept(analyzer)
      analyzer.analyze_person(self)
      payments.each do |payment|
        payment.accept(analyzer)
      end
    end
  end
end
