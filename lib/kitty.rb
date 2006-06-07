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
#   group 'Car1', 'Bou', 'Fred', 'Sosoph'
#   group 'Car2', 'Gwenn', 'Medo', 'Seb'
#
#   Seb.pay 45, :purpose => 'petrol', :include => Car2
#   Sosoph.pay 40, :purpose => 'toll', :include => Car1
#   Fred.pay 50, :purpose => 'petrol', :include => Car1
#   Medo.pay 37, :purpose => 'restaurant', :exclude => [Fred, Gwenn]
#   Fred.pay 70, :purpose => 'makina', :exclude => Gwenn
#   Sosoph.pay 6, :purpose => 'makina', :exclude => Gwenn
#
#   Bou.pay 57, 'foodstuffs'
#   Gwenn.pay 16, 'foodstuffs'
#   Medo.pay 70, 'foodstuffs'
#   Seb.pay 14, 'foodstuffs'
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
require 'mathn'
require 'rational'

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

  # A group of persons making common expenses.
  class Trip
    attr_reader :name
    attr_reader :period
    include PersonSet

    def initialize(name, period = nil)
      raise(ArgumentError, 'Illegal nil or empty name', caller) if name.nil? || name.empty?
      @name = name
      @period = period
    end

    def groups
      @groups ||= Set.new
    end

    def add(persons_or_groups)
      if persons_or_groups.is_a?(Kitty::Group)
        groups << persons_or_groups
      end
      super(persons_or_groups)
    end

    # Calculates credit and debit balances and then suggests optimal repayments.
    #--
    # TODO Find a better name
    def balance
      raise('No person toke part to these trip!') if persons.empty?

      balancer = Balancer.new
      accept(balancer)
      balances = balancer.balances # { person => balance }

      display_details(balances, balancer.total)

      balances.reject! do |person, balance|
        balance.zero?
      end

      unless balances.empty?
        apportioner = Apportioner.new
        creditors, repayments, debtors = apportioner.distribute(balances)

        unless repayments.nil? || repayments.empty?
          display_repayments(creditors, repayments, debtors)
        end
      end
    end

    # +Visitor+ pattern : _Element_
    def accept(analyzer)
      analyzer.analyze_trip(self)
      persons.each do |person|
        person.accept(analyzer)
      end
    end

    protected
    def display_details(balances, total)
      puts('Trip: %s' % @name)
      puts('  Total: %.2f' % [Payment.to_f(total)])
      puts
      result = balances.sort do |a, b|
        a[0].name <=> b[0].name
      end
      check_sum = 0
      result.each do |r|
        puts('  %s: %.2f' % [r[0].name, Payment.to_f(r[1])])
        check_sum += r[1]
      end

      puts
      puts('  Balance: %i' % [check_sum.abs])
      puts
    end

    def display_repayments(creditors, repayments, debtors)
      puts('%i choice(s):' % repayments.size)
      repayments.each_with_index do |transfers, choice|
        unless 0 == choice
          puts('Or')
        end
        transfers.each_index do |i|
          transfers[i].each_index do |j|
            unless transfers[i][j] == 0
              puts('  %s -> %s: %.2f' % [debtors[j].name,
                  creditors[i].name, Payment.to_f(transfers[i][j])])
            end
          end
        end
      end
      puts
    end
  end

  # A sub-group of persons making common expenses.
  #--
  # FIXME add @period ?
  class Group
    attr_reader :name
    include PersonSet

    def initialize(name)
      raise(ArgumentError, 'Illegal nil or empty name', caller) if name.nil? || name.empty?
      @name = name
    end
  end

  # A person taking part in a Trip.
  class Person
    attr_reader :name
    attr_accessor :period
    attr_reader :pay_back_persons

    def initialize(name, period = nil)
      raise(ArgumentError, 'Illegal nil or empty name', caller) if name.nil? || name.empty?
      @name = name
      @period = period
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

    def arrive()
      @period = nil
    end

    def leave()
      @period = nil
    end

    # +Visitor+ pattern : _Element_
    def accept(analyzer)
      analyzer.analyze_person(self)
      payments.each do |payment|
        payment.accept(analyzer)
      end
    end
  end

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
      concerned_person_set = Object.new.extend(Kitty::PersonSet)
      if payment.included_persons_or_groups.nil?
        concerned_person_set << @trip.persons
      else
        concerned_person_set << payment.included_persons_or_groups << payment.payer
      end
      concerned_person_set.delete(payment.excluded_persons_or_groups) unless payment.excluded_persons_or_groups.nil?
      concerned_persons = concerned_person_set.persons
      unless payment.date.nil?
        concerned_persons.reject! do |person|
          !(person.period.nil?) and !(person.period.include?(payment.date))
        end
      end
      raise("No Concerned person for #{payment}!") if concerned_persons.empty?
      @balances[payment.payer] += payment.amount_i
      share = payment.amount_i / concerned_persons.size
      concerned_persons.each do |person|
        @balances[person] -= share
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

  # Balance for one Person.
  Balance = Struct.new('Balance', :person, :value)
  
  # Divides up repayments in such a way that the number of repayments is minimal.
  # All optimal combinations are returns.
  class Apportioner
    # FIXME: Full objects, not hashes! http://rpa-base.rubyforge.org/wiki/wiki.cgi?GoodAPIDesign
    def distribute(balances) # { person => balance }
      return nil if balances.empty?

      balances = balances.collect do |person, balance|
        Balance.new(person, balance)
      end

      credit_balances, debit_balances = balances.partition do |balance|
        balance.value > 0
      end

      credit_balances.sort! do |x, y|
        y.value <=> x.value
      end
      debit_balances.sort! do |x, y|
        y.value <=> x.value
      end

      transfers = matrix_zero(credit_balances.size, debit_balances.size)
      # If some persons prefer to pay back other ones:
      # FIXME Display pay back constraints ignored
      debit_balances.each_index do |j|
        debtor = debit_balances[j].person
        unless debtor.pay_back_persons.nil? || debtor.pay_back_persons.empty?
          debtor.pay_back_persons.each do |pay_back_person|
            credit_balances.each_index do |i|
              creditor = credit_balances[i].person
              if pay_back_person == creditor
                unless debit_balances[j].value.zero? || credit_balances[i].value.zero?
                  transfer = [debit_balances[j].value.abs, credit_balances[i].value].min
                  transfers[i][j] = transfer
                  debit_balances[j].value += transfer
                  credit_balances[i].value -= transfer
                end
              end
            end
          end
        end
      end

      repayments = optimize(credit_balances.collect { |c| c.value }, transfers,
                            debit_balances.collect { |d| d.value } )
      [credit_balances.collect{ |c| c.person }, repayments, debit_balances.collect { |d| d.person } ]
    end
    
    private
    def optimize( credit_balances, transfers, debit_balances )
      perms = Permutation.new( debit_balances.size )
      repayments = []
      min_repayment = 0
      perms.each do |perm|
        min_repayment = repay(credit_balances.dup, matrix_dup(transfers),
                              debit_balances.dup, perm, repayments,
                              min_repayment)
      end
      repayments
    end

    def repay(credit_balances, transfers, debit_balances, perm, repayments,
              min_repayment)
      repayment_count = 0
      perm.each_index do |k|
        j = perm[k]
        credit_balances.each_index do |i|
          unless debit_balances[j].zero? || credit_balances[i].zero?
            transfer = [debit_balances[j].abs, credit_balances[i]].min
            transfers[i][j] = transfer
            debit_balances[j] += transfer
            credit_balances[i] -= transfer
            repayment_count += 1
          end
        end
      end
      if repayment_count < min_repayment || repayments.empty?
        min_repayment = repayment_count
        repayments.clear
        repayments << transfers
      elsif repayment_count == min_repayment
        unless repayments.include?(transfers)
          repayments << transfers
        end
      end
      min_repayment
    end

    def matrix_zero(rows, cols)
      m = []
      rows.times do
        m << Array.new( cols, 0 )
      end
      m
    end

    def matrix_dup(m)
      m_dup = []
      m.each do |row|
        m_dup << row.dup
      end
      m_dup
    end
  end

  # See http://permutation.rubyforge.org (Florian Frank)
  # But its factorial method does not work in $SAFE = 4 mode! 
  class Permutation
    def initialize(size)
      @size = size
      @last = factorial(size) - 1
    end

    def each
        0.upto(@last) do |r|
            yield unrank_indices(r)
        end
    end

    private
    def factorial(n)
        f = 1
        for i in 2..n do f *= i end
        f
    end

    def unrank_indices(m)
        result = Array.new(@size, 0)
        for i in 0...@size
            f = factorial(i)
            x = m % (f * (i + 1))
            m -= x
            x /= f
            result[@size - i - 1] = x
            x -= 1
            for j in (@size - i)...@size
                result[j] += 1 if result[j] > x
            end
        end
        result
    end
  end

  # Serializes one Trip in memory to a DSL stream.
  class ToDSLSerializer
    attr_reader :io

    def initialize(io)
      raise(ArgumentError, 'Illegal stream', caller) unless io.respond_to?(:to_io)
      @io = io.to_io
    end

    def analyze_trip(trip)
      # FIXME How to retreive Groups?
      io.print 'trip \'%s\'' % trip.name
      io.puts
    end

    def end_trip(trip)
      trip.each do |person|
        unless person.pay_back_persons.nil? || person.pay_back_persons.empty?
          person.pay_back_persons.each do |pay_back_person|
            io.puts '%s.prefer_to_pay_back %s' % [person.name, pay_back_person.name]
          end
        end
      end
      io.puts
      io.puts 'checkout'
      io.puts
    end

    def analyze_person(person)
      # TODO person.period
    end

    def analyze_payment(payment)
      # TODO date
      io.print '%s.pay %.2f, :purpose => \'%s\'' % [payment.payer.name, payment.amount, payment.purpose]
      unless payment.included_persons_or_groups.nil?
        io.print ', :include => '
        if payment.included_persons_or_groups.is_a?(Array)
          io.print '['
          payment.included_persons_or_groups.each do |included_person_or_group|
            io.print '%s, ' % included_person_or_group.name
          end
          io.print ']'
        else
          io.print '%s' % payment.included_persons_or_groups.name
        end
      end
      unless payment.excluded_persons_or_groups.nil?
        io.print ', :exclude => '
        if payment.excluded_persons_or_groups.is_a?(Array)
          io.print '['
          payment.excluded_persons_or_groups.each do |excluded_person_or_group|
            io.print '%s, ' % excluded_person_or_group.name
          end
          io.print ']'
        else
          io.print '%s' % payment.excluded_persons_or_groups.name
        end
      end
      io.puts
      io.puts 'checkout'
      io.puts
    end
  end

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

  module DSL
    #def DSL.extended(obj) FIXME
    #end

    # Declares the current Trip.
    # 
    # <b>+name+ must be capitalized</b>.
    def trip(name, *persons)
      trip = singleton_class.const_set(name, Kitty::Trip.new(name, Period.new))
      singleton_class.const_set(:TRIP, trip)
      persons.each do |person|
        trip << create_person(person)
      end
      trip
    end
    
    # Declares one Person taking part in the current trip.
    # 
    # <b>+name+ must be capitalized</b>.
    def person(name, period = nil)
      person = singleton_class.const_set(name, Kitty::Person.new(name, period))
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

    def day(day = nil) # FIXME How to take into account any parameter passed?
      current_trip.period.inc
    end
    
    private
    def create_person(name, period = nil)
      singleton_class.const_set(name, Kitty::Person.new(name, period))
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
        const_set(:TRIP, Kitty::Trip.new('One trip', Period.new))
      end
      const_get(:TRIP) << person
      person
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
        #thr = Thread.new do
          #ctx.taint
          #file.taint
          #$SAFE = 4
          ctx.instance_eval(file.read, arg, 1)
        #end
        #thr.join
      end
    end
  else
    puts('Missing trip data')
    RDoc::usage('Usage')
  end

  at_exit { puts('ByeBye...') }
end
