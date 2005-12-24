$:.unshift(File.join(File.dirname(__FILE__), "..", "lib"))
require 'test/unit'
require 'kitty'
require 'date'

module TestKitty
  class TestPayment < Test::Unit::TestCase
    def setup
      @payer = Kitty::Person.new('Test')
      @payment = Kitty::Payment.new(@payer, 10, 'misc')
    end

    def test_initial_state
      assert_same(@payer, @payment.payer)
      assert_same(10, @payment.amount)
      assert_equal('misc', @payment.purpose)
      assert_nil(@payment.date)
      assert_nil(@payment.included_persons)
      assert_nil(@payment.excluded_persons)
    end

    def test_included_persons
      included0 = Kitty::Person.new('included0')
      included1 = Kitty::Person.new('included1')
      @payment = Kitty::Payment.new(@payer, 10, :purpose => 'misc', :include => [included0, included1])
      assert_same(@payer, @payment.payer)
      assert_same(10, @payment.amount)
      assert_equal('misc', @payment.purpose)
      assert_nil(@payment.date)
      assert_same(2, @payment.included_persons.length)
      assert(@payment.included_persons.include?(included0))
      assert(@payment.included_persons.include?(included1))
      assert_nil(@payment.excluded_persons)
    end

    def test_excluded_persons
      excluded0 = Kitty::Person.new('excluded0')
      excluded1 = Kitty::Person.new('excluded1')
      @payment = Kitty::Payment.new(@payer, 10, :purpose => 'misc', :exclude => [excluded0, excluded1])
      assert_same(@payer, @payment.payer)
      assert_same(10, @payment.amount)
      assert_equal('misc', @payment.purpose)
      assert_nil(@payment.date)
      assert_nil(@payment.included_persons)
      assert_same(2, @payment.excluded_persons.length)
      assert(@payment.excluded_persons.include?(excluded0))
      assert(@payment.excluded_persons.include?(excluded1))
    end

    def test_date
      date = Date.new
      @payment = Kitty::Payment.new(@payer, 10, :purpose => 'misc', :date => date)
      assert_same(@payer, @payment.payer)
      assert_same(10, @payment.amount)
      assert_equal('misc', @payment.purpose)
      assert_same(date, @payment.date)
      assert_nil(@payment.included_persons)
      assert_nil(@payment.excluded_persons)
    end

    def teardown
      @payment = nil
      @payer = nil
    end
  end
end