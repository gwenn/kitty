# Copyright (c) 2005 El Barto.
# 
# Licensed under the same terms as Ruby.
require 'mathn'
require 'rational'
require 'kitty/personset'

module Kitty
  # Calculates credit and debit balances.
  #
  # +Visitor+ pattern : _Visitor_
  class Balancer
    # FIXME: Full objects, not hashes! http://rpa-base.rubyforge.org/wiki/wiki.cgi?GoodAPIDesign
    # { person => balance }
    attr_reader :balances
    attr_reader :total

    def analyze_trip(trip)
      @trip = trip
      init_balances(trip)
      @total = 0
    end

    def analyze_person(person)
    end

    def analyze_payment(payment)
      @total += payment.amount_i
      update_balances(payment)
    end

    private
    def update_balances(payment)
      beneficiary_set = Object.new.extend(Kitty::PersonSet)
      if payment.included_persons_or_groups.nil?
        beneficiary_set << @trip.persons
      else
        beneficiary_set << payment.included_persons_or_groups << payment.payer
      end
      beneficiary_set.delete(payment.excluded_persons_or_groups) unless payment.excluded_persons_or_groups.nil?
      beneficiaries = beneficiary_set.persons
      unless payment.date.nil?
        beneficiaries.reject! do |beneficiary|
          !(beneficiary.period.nil?) and !(beneficiary.period.include?(payment.date))
        end
      end
      raise("No Beneficiary for #{payment}!") if beneficiaries.empty?
      @balances[payment.payer] += payment.amount_i
      share = payment.amount_i / beneficiaries.size
      beneficiaries.each do |beneficiary|
        @balances[beneficiary] -= share
      end
    end
    def init_balances(trip)
      @balances = {}
      trip.persons.each do |person|
        @balances[person] = 0
      end
      @balances
    end
  end
end
