# Copyright (c) 2005 El Barto.
# 
# Licensed under the same terms as Ruby.
module Kitty
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
end
