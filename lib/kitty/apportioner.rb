# Copyright (c) 2005 El Barto.
# 
# Licensed under the same terms as Ruby.
require 'mathn'
require 'rational'
require 'kitty/permutation'

module Kitty
  # Balance for one Person.
  Balance = Struct.new('Balance', :person, :state)
  
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
        balance.state > 0
      end

      credit_balances.sort! do |x, y|
        y.state <=> x.state
      end
      debit_balances.sort! do |x, y|
        y.state <=> x.state
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
                unless debit_balances[j].state.zero? || credit_balances[i].state.zero?
                  transfer = [debit_balances[j].state.abs, credit_balances[i].state].min
                  transfers[i][j] = transfer
                  debit_balances[j].state += transfer
                  credit_balances[i].state -= transfer
                end
              end
            end
          end
        end
      end

      repayments = optimize(credit_balances.collect { |c| c.state }, transfers,
                            debit_balances.collect { |d| d.state } )
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
end
