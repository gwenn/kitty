# == Synopsis
#
# Helps to keep Group accounting.
# Original idea came from {Christian Neukirchen}[http://chneukirchen.org/blog/archive/2005/05/scripting-for-runaways.html].
#
# == Usage
#    ruby kitty.rb [-h | --help] trip_data...
#
# trip_data::
#    A file describing the expenses made for one trip.
#
#   trip 'Neons'
#
#   group 'Break', 'Bou', 'Fred', 'Sosoph'
#   group 'Advantime', 'Gwenn', 'Medo', 'Seb'
#
#   Seb.pay 45.00, :purpose => 'Essence', :include => Advantime
#   Sosoph.pay 40.00, :purpose => 'Peage', :include => Break
#   Fred.pay 50.00, :purpose => 'Essence', :include => Break
#   Medo.pay 37.00, :purpose => 'Resto', :exclude => [Fred, Gwenn]
#   Fred.pay 70.00, :purpose => 'Makina', :exclude => Gwenn
#   Sosoph.pay 6.00, :purpose => 'Makina', :exclude => Gwenn
#
#   Bou.pay 57.00, 'Nourriture'
#   Gwenn.pay 16.00, 'Nourriture'
#   Medo.pay 70.00, 'Nourriture'
#   Seb.pay 14.00, 'Nourriture'
#
#   Gwenn.prefer_to_pay_back Medo
#   Sosoph.prefer_to_pay_back Fred
#
#   balance
#
# == Author
# El Barto
#
# == Copyright
# Copyright (c) 2005 El Barto.
# Licensed under the same terms as Ruby.
require 'set'
require 'date'

module Kitty
  module PersonSet
    include Enumerable

    def persons
      @persons ||= Set.new
    end

    def add(*persons)
      persons.each do |elt|
        if elt.respond_to?(:each)
          self.persons.merge(elt)
        else
          self.persons.add(elt)
        end
      end
      self
    end
    alias :<< :add

    def each
      persons.each do |person|
        yield(person)
      end
      self
    end
  end

  class Trip
    attr_reader :name
    attr_reader :period
    include PersonSet

    def initialize(name, period = nil)
      raise(ArgumentError, 'Illegal nil or empty name', caller) if name.nil? || name.empty?
      @name = name
      @period = period
    end

    def balance
      raise('No person toke part to these trip!') if @persons.nil? || @persons.empty?

      balancer = Balancer.new
      accept(balancer)
      balances = balancer.balances # { person => balance }

      display_details(balances, balancer.total)

      apportioner = Apportioner.new
      repayments = apportioner.distribute(balances.dup)

      display_repayments(repayments)
    end

    def accept(analyzer)
      analyzer.analyze_trip(self)
      @persons.each do |person|
        person.accept(analyzer)
      end
    end

    protected
    def display_details(balances, total)
      puts('Trip: %s' % @name)
      puts('  Total: %.2f' % [total])
      puts
      result = balances.sort do |a, b|
        a[0].name <=> b[0].name
      end
      check_sum = 0.0
      result.each do |r|
        puts('  %s: %.2f' % [r[0].name, r[1]])
        check_sum += r[1]
      end

      puts
      puts('  Balance: %.2f' % [check_sum.abs])
      puts
    end

    def display_repayments(repayments)
      repayments.each do |repayment|
        puts('  %s -> %s: %.2f' % [repayment[0].name, repayment[1].name, repayment[2]])
      end
      puts
    end
  end

  class Group # FIXME add @period ?
    attr_reader :name
    include PersonSet

    def initialize(name)
      raise(ArgumentError, 'Illegal nil or empty name', caller) if name.nil? || name.empty?
      @name = name
    end
  end

  class Person
    attr_reader :name
    attr_accessor :period
    attr_reader :pay_back_persons

    def initialize(name, period = nil)
      raise(ArgumentError, 'Illegal nil or empty name', caller) if name.nil? || name.empty?
      @name = name
      @period = period
    end

    def payments
      @payments ||= []
    end

    def pay(amount, desc = 'stuff')
      payments << Payment.new(self, amount, desc)
      self
    end

    def lend(amount, purpose, *persons)
      payments << Payment.new(self, amount, { :purpose => purpose, :exclude => self, :include => persons })
      self
    end

    def prefer_to_pay_back(*persons) # FIXME destructive method
      @pay_back_persons = persons
    end

    def accept(analyzer)
      analyzer.analyze_person(self)
      payments.each do |payment|
        payment.accept(analyzer)
      end
    end
  end

  class Payment
    attr_reader :payer, :amount, :purpose, :date
    attr_reader :included_persons, :excluded_persons

    def initialize(payer, amount, desc)
      @payer = payer
      @amount = amount
      if desc.respond_to?(:to_hash)
        hash = desc.to_hash
        @purpose = hash[:purpose]
        @date = hash[:date]
        if hash.has_key?(:include)
          if hash[:include].respond_to?(:each)
            @included_persons = Set.new(hash[:include])
          else
            @included_persons = Set.new
            @included_persons << hash[:include]
          end
        else
          @included_persons = nil
        end
        if hash.has_key?(:exclude)
          if hash[:exclude].respond_to?(:each)
            @excluded_persons = Set.new(hash[:exclude])
          else
            @excluded_persons = Set.new
            @excluded_persons << hash[:exclude]
          end
        else
          @excluded_persons = nil
        end
      else
        @purpose = desc
        @date = nil
        @included_persons = nil
        @excluded_persons = nil
      end
    end

    def accept(analyzer)
      analyzer.analyze_payment(self)
    end
  end

  class Balancer
    attr_reader :balances # { person => balance }
    attr_reader :total

    def analyze_trip(trip)
      @trip = trip
      init_balances(trip)
      @total = 0.0
    end

    def analyze_person(person)
    end

    def analyze_payment(payment)
      @total += payment.amount
      update_balances(payment)
    end

    private
    def update_balances(payment)
      if payment.included_persons.nil? || payment.included_persons.empty?
        concerned_persons = @trip.persons.dup
      else
        concerned_persons = payment.included_persons.dup << payment.payer
      end
      concerned_persons.subtract(payment.excluded_persons) unless payment.excluded_persons.nil?
      unless payment.date.nil?
        concerned_persons.reject! do |person|
          !(person.period.nil?) and !(person.period.include?(payment.date))
        end
      end
      raise("No Concerned person for #{payment}!") if concerned_persons.empty?
      @balances[payment.payer] += payment.amount
      share = payment.amount / concerned_persons.size
      concerned_persons.each do |person|
        @balances[person] -= share
      end
    end
    def init_balances(trip)
      @balances = {}
      trip.persons.each do |person|
        @balances[person] = 0.0
      end
      @balances
    end
  end

  class Apportioner
    def distribute(balances) # { person => balance }
      repayments = [] # [ receiver, donor, repayment ]
      # If some persons prefer to pay back other ones:
      balances.each do |person, balance|
        unless person.pay_back_persons.nil? || person.pay_back_persons.empty?
          if balance < 0
            person.pay_back_persons.each do |pay_back_person|
              pay_back_balance = balances[pay_back_person]
              if pay_back_balance > 0
                repayment = [balance.abs, pay_back_balance].min
                balance += repayment
                balances[pay_back_person] -= repayment
                repayments << [person, pay_back_person, repayment]
              end
            end
          else
            puts('Pay back constraint for %s ignored!' % [person.name])
          end
          balances[person] = balance
        end
      end

      balances.reject! do |person, balance|
        balance.zero?
      end

      donors, receivers = balances.partition do |person, balance|
        balance > 0
      end

      # To make sure receivers with low balance (near zero) pay as few donors as possible,
      # receivers with low balance are treated first and pay donors with high balance.
      receivers.sort! do |x, y|
        y[1] <=> x[1]
      end

      receivers.each do |receiver|
        donors.sort! do |x, y|
          y[1] <=> x[1]
        end

        donors.each do |donor|
          unless receiver[1].zero? || donor[1].zero?
            repayment = [receiver[1].abs, donor[1]].min
            receiver[1] += repayment
            donor[1] -= repayment
            repayments << [receiver[0], donor[0], repayment]
          end
        end
      end
      repayments
    end
  end

  module DSL
    #def DSL.extended(obj) FIXME
    #end

    def trip(name, *persons)
      trip = singleton_class.const_set(name, Kitty::Trip.new(name))
      singleton_class.const_set(:TRIP, trip)
      persons.each do |person|
        person(person)
      end
      trip
    end

    def person(name, period = nil)
      person = singleton_class.const_set(name, Kitty::Person.new(name, period))
      current_trip << person
      person
    end

    def group(name, *persons)
      group = singleton_class.const_set(name, Kitty::Group.new(name))
      persons.collect! do |person|
        if person.is_a?(Kitty::Person)
          person
        else
          person(person)
        end
      end
      group.add(*persons)
      group
    end

    def balance
      current_trip.balance()
    end
    alias :checkout :balance

    private
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

  class Trick
    include DSL

    def Trick.const_missing(sym)
      warn("Constante '%s' was not declared! The corresponding person is created." % sym)
      person(sym)
    end
  end
end

if __FILE__ == $0
  require 'optparse'
  require 'rdoc/usage'

  opts = OptionParser.new
  opts.on('-h', '--help') { RDoc::usage }
  begin
    opts.parse(ARGV)
  rescue => error
    puts(error.message)
    RDoc::usage('Usage')
  end

  unless ARGV.empty?
    ARGV.each do |arg|
      ctx = Kitty::Trick.new
      File.open(arg) do |file|
        ctx.instance_eval(file.read, arg, 1)
      end
    end
  else
    puts('Missing trip data')
    RDoc::usage('Usage')
  end

  at_exit { puts('ByeBye...') }
end
