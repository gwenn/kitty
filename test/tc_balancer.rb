$:.unshift(File.join(File.dirname(__FILE__), "..", "lib"))
require 'test/unit'
require 'kitty'
require 'date'

module TestKitty
  class TestBalancer < Test::Unit::TestCase
    def setup
      @trip = Kitty::Trip.new('Test')
      @person0 = Kitty::Person.new('Person0', Date.new(2005, 9, 10)..Date.new(2005, 9, 25))
      @person1 = Kitty::Person.new('Person1')
      @person2 = Kitty::Person.new('Person2')
      @balancer = Kitty::Balancer.new
    end

    def test_analyze_trip
      @trip.accept(@balancer)
      assert_in_delta(0.0, @balancer.total, 0.001)
      assert(@balancer.balances.empty?)
    end

    def test_analyze_person
      @trip.add(@person0)
      @trip.add(@person1)
      @trip.accept(@balancer)
      assert_in_delta(0.0, @balancer.total, 0.001)
      assert(2, @balancer.balances.length)
      assert(@balancer.balances.include?(@person0))
      assert_in_delta(0.0, @balancer.balances[@person0], 0.001)
      assert(@balancer.balances.include?(@person1))
      assert_in_delta(0.0, @balancer.balances[@person1], 0.001)
    end

    def test_analyze_payment
      @trip.add(@person0)
      @trip.add(@person1)
      @person0.pay(10.0)
      @trip.accept(@balancer)
      assert_in_delta( 10.0, @balancer.total, 0.001)
      assert_in_delta(5.0, @balancer.balances[@person0], 0.001)
      assert_in_delta(-5.0, @balancer.balances[@person1], 0.001)
    end

    def test_analyze_payments
      @trip.add(@person0)
      @trip.add(@person1)
      @person0.pay(10.0)
      @person1.pay(20.0)
      @trip.accept(@balancer)
      assert_in_delta( 30.0, @balancer.total, 0.001)
      assert_in_delta(-5.0, @balancer.balances[@person0], 0.001)
      assert_in_delta(5.0, @balancer.balances[@person1], 0.001)
    end

    def test_analyze_payment_with_exclude_and_indclude
      @trip.add(@person0)
      @trip.add(@person1)
      @person0.lend(10.0, 'misc', @person1)
      @trip.accept(@balancer)
      assert_in_delta( 10.0, @balancer.total, 0.001)
      assert_in_delta(10.0, @balancer.balances[@person0], 0.001)
      assert_in_delta(-10.0, @balancer.balances[@person1], 0.001)
    end

    def test_analyze_payment_with_date
      @trip.add(@person0)
      @trip.add(@person1)
      @trip.add(@person2)
      @person1.pay(10.0, :date => Date.new(2005, 9, 9))
      @trip.accept(@balancer)
      assert_in_delta( 10.0, @balancer.total, 0.001)
      assert_in_delta(0.0, @balancer.balances[@person0], 0.001)
      assert_in_delta(5.0, @balancer.balances[@person1], 0.001)
      assert_in_delta(-5.0, @balancer.balances[@person2], 0.001)
    end

    def test_analyze_payment_with_no_person
      @trip.add(@person0)
      @trip.add(@person1)
      @person0.pay(10.0, :exclude => [@person0, @person1])
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
  end
end
