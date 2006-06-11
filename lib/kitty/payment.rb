# Copyright (c) 2005 El Barto.
# 
# Licensed under the same terms as Ruby.
require 'mathn'
require 'rational'

module Kitty
  # Common expense.
  class Payment
    # Specifies the precision of numeric calculations.
    PRECISION = 2
    attr_reader :payer, :purpose, :date
    attr_reader :included_persons_or_groups, :excluded_persons_or_groups

    # FIXME: Many arguments! Named them : http://rpa-base.rubyforge.org/wiki/wiki.cgi?GoodAPIDesign
    def initialize(payer, amount, desc)
      @payer = payer
      @amount = Payment.to_i(amount)
      if desc.respond_to?(:to_hash)
        hash = desc.to_hash
        @purpose = hash[:purpose]
        @date = hash[:date]
        if hash.has_key?(:include)
          @included_persons_or_groups = hash[:include]
        else
          @included_persons_or_groups = nil
        end
        if hash.has_key?(:exclude)
          @excluded_persons_or_groups = hash[:exclude]
        else
          @excluded_persons_or_groups = nil
        end
      else
        @purpose = desc
        @date = nil
        @included_persons_or_groups = nil
        @excluded_persons_or_groups = nil
      end
    end

    # +Visitor+ pattern : _Element_
    def accept(analyzer)
      analyzer.analyze_payment(self)
    end

    def amount
      Payment.to_f(@amount)
    end
    
    # Returns the integer form of the amount.
    # Indeed, all internal calculations are made with integers.
    def amount_i
      @amount
    end

    # Converts an integer amount in a decimal depending on the current precision.
    def Payment.to_f(amount)
      amount * 10**-PRECISION
    end

    # Converts an amount in an integer depending on the current precision.
    def Payment.to_i(amount)
      (amount * 10**PRECISION).to_i
    end
  end  
end
