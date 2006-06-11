# Copyright (c) 2005 El Barto.
# 
# Licensed under the same terms as Ruby.
require 'set'
require 'kitty/apportioner'
require 'kitty/balancer'
require 'kitty/group'
require 'kitty/payment'
require 'kitty/personset'

module Kitty
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
      super
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
      raise('Non-zero balance!') unless check_sum.abs.zero?
    end

    def display_repayments(creditors, repayments, debtors)
      puts('%i choices:' % repayments.size) if 1 < repayments.size
      repayments.each_with_index do |transfers, choice|
        unless choice.zero?
          puts('Or')
        end
        transfers.each_index do |i|
          transfers[i].each_index do |j|
            unless transfers[i][j].zero?
              puts('  %s -> %s: %.2f' % [debtors[j].name,
                  creditors[i].name, Payment.to_f(transfers[i][j])])
            end
          end
        end
      end
      puts
    end
  end  
end
