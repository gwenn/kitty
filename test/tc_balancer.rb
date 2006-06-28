$:.unshift(File.join(File.dirname(__FILE__), "..", "lib"))
require 'test/unit'
require 'kitty'

module TestKitty
  class TestBalancer < Test::Unit::TestCase
    def setup
      @trip = Kitty::Trip.new('Test')
      @person0 = Kitty::Person.new('Person0')
      @person1 = Kitty::Person.new('Person1')
      @person2 = Kitty::Person.new('Person2')
      @balancer = Kitty::Balancer.new
    end

    def test_analyze_trip
      @trip.accept(@balancer)
      assert_amount(0, @balancer.total)
      assert(@balancer.balances.empty?)
    end

    def test_analyze_person
      @trip.add(@person0)
      @trip.add(@person1)
      @trip.accept(@balancer)
      assert_amount(0, @balancer.total)
      assert(2, @balancer.balances.length)
      assert(@balancer.balances.include?(@person0))
      assert_amount(0, @balancer.balances[@person0])
      assert(@balancer.balances.include?(@person1))
      assert_amount(0, @balancer.balances[@person1])
    end

    def test_analyze_payment
      @trip.add(@person0)
      @trip.add(@person1)
      @person0.pay(10)
      @trip.accept(@balancer)
      assert_amount(10, @balancer.total)
      assert_amount(5, @balancer.balances[@person0])
      assert_amount(-5, @balancer.balances[@person1])
    end

    def test_analyze_payments
      @trip.add(@person0)
      @trip.add(@person1)
      @person0.pay(10)
      @person1.pay(20)
      @trip.accept(@balancer)
      assert_amount(30, @balancer.total)
      assert_amount(-5, @balancer.balances[@person0])
      assert_amount(5, @balancer.balances[@person1])
    end

    def test_analyze_payment_with_exclude_and_indclude
      @trip.add(@person0)
      @trip.add(@person1)
      @person0.lend(10, 'misc', @person1)
      @trip.accept(@balancer)
      assert_amount(10, @balancer.total)
      assert_amount(10, @balancer.balances[@person0])
      assert_amount(-10, @balancer.balances[@person1])
    end

    def test_analyze_payment_with_no_person
      @trip.add(@person0)
      @trip.add(@person1)
      @person0.pay(10, :exclude => [@person0, @person1])
      assert_raise(RuntimeError) {
        @trip.accept(@balancer)
      }
    end
    
    def teardown
      @balancer = nil
      @person0 = nil
      @person1 = nil
      @person2 = nil
      @trip = nil
    end

    private
    def assert_amount(expected, actual)
      assert(Kitty::Payment.to_i(expected), actual)
    end
  end
end
