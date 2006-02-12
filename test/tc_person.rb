$:.unshift(File.join(File.dirname(__FILE__), "..", "lib"))
require 'test/unit'
require 'kitty'
require 'date'

module TestKitty
  class TestPerson < Test::Unit::TestCase
    def setup
      @person = Kitty::Person.new('Test')
    end

    def test_initial_state
      assert_equal('Test', @person.name)
      assert_nil(@person.period)
      assert(@person.payments.empty?)
      assert_nil(@person.pay_back_persons)
    end

    def test_period
      period = Date.new(2005, 9, 10)..Date.new(2005, 9, 25)
      @person = Kitty::Person.new('Test', period)
      assert_equal('Test', @person.name)
      assert_same(period, @person.period)
      assert(@person.payments.empty?)
      assert_nil(@person.pay_back_persons)
    end

    def test_no_name
      assert_raise(ArgumentError) {
        Kitty::Person.new(nil)
      }
      assert_raise(ArgumentError) {
        Kitty::Person.new('')
      }
    end

    def test_pay
      @person.pay(10)
      assert_equal(1, @person.payments.length)
      payment = @person.payments[0]
      assert_same(@person, payment.payer)
      assert_equal(10, payment.amount)
      assert_equal('stuff', payment.purpose)

      @person.pay(5, 'misc')
      assert_equal(2, @person.payments.length)
      payment = @person.payments[1]
      assert_same(@person, payment.payer)
      assert_equal(5, payment.amount)
      assert_equal('misc', payment.purpose)

      @person.pay(1).pay(2)
    end

    def test_lend
      receiver0 = Kitty::Person.new('receiver0')
      receiver1 = Kitty::Person.new('receiver1')
      @person.lend(10, 'misc', receiver0, receiver1)
      assert_same(1, @person.payments.length)
      payment = @person.payments[0]
      assert_same(@person, payment.payer)
      assert_equal(10, payment.amount)
      assert_equal('misc', payment.purpose)
      assert_equal(2, payment.included_persons_or_groups.length)
      assert(payment.included_persons_or_groups.include?(receiver0))
      assert(payment.included_persons_or_groups.include?(receiver1))
      assert_equal(@person, payment.excluded_persons_or_groups)
    end

    def test_prefer_to_back
      donor0 = Kitty::Person.new('donor0')
      donor1 = Kitty::Person.new('donor1')
      @person.prefer_to_pay_back(donor0, donor1)
      assert_equal(2, @person.pay_back_persons.length)
      assert(@person.pay_back_persons.include?(donor0))
      assert(@person.pay_back_persons.include?(donor1))
    end

    def teardown
      @person = nil
    end
  end
end
