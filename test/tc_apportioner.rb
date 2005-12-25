$:.unshift(File.join(File.dirname(__FILE__), "..", "lib"))
require 'test/unit'
require 'kitty'

module TestKitty
  class TestApportioner < Test::Unit::TestCase
    def setup
      @person0 = Kitty::Person.new('Person0')
      @person1 = Kitty::Person.new('Person1')
      @person2 = Kitty::Person.new('Person2')
      @person3 = Kitty::Person.new('Person3')
      @balances = {}
      @apportioner = Kitty::Apportioner.new
    end

    def test_distribute_with_empty_balances
      repayments = nil
      assert_nothing_raised {
        repayments = @apportioner.distribute(@balances)
      }
      assert(repayments.empty?)
    end

    def test_distribute
      @balances[@person0] = 5.00
      @balances[@person1] = -5.00
      repayments = @apportioner.distribute(@balances)
      assert_equal(1, repayments.length)
      assert_equal(@person1, repayments[0][0])
      assert_equal(@person0, repayments[0][1])
      assert_in_delta(5.00, repayments[0][2], 0.001)
    end

    def test_distribute_order
      @balances[@person0] = 25.00
      @balances[@person1] = 10.00
      @balances[@person2] = -15.00
      @balances[@person3] = -20.00
      repayments = @apportioner.distribute(@balances)
      assert_equal(3, repayments.length)
      assert_equal(@person2, repayments[0][0])
      assert_equal(@person0, repayments[0][1])
      assert_in_delta(15.00, repayments[0][2], 0.001)

      assert_equal(@person3, repayments[1][0])
      assert_equal(@person0, repayments[1][1])
      assert_in_delta(10.00, repayments[1][2], 0.001)

      assert_equal(@person3, repayments[2][0])
      assert_equal(@person1, repayments[2][1])
      assert_in_delta(10.00, repayments[2][2], 0.001)
    end

    def test_distribute_with_prefer_to_pay_back
      @person2.prefer_to_pay_back(@person1)
      @balances[@person0] = 15.00
      @balances[@person1] = 15.00
      @balances[@person2] = -10.00
      @balances[@person3] = -20.00
      repayments = @apportioner.distribute(@balances)
      assert_equal(3, repayments.length)
      assert_equal(@person2, repayments[0][0])
      assert_equal(@person1, repayments[0][1])
      assert_in_delta(10.00, repayments[0][2], 0.001)

      assert_equal(@person3, repayments[1][0])
      assert_equal(@person0, repayments[1][1])
      assert_in_delta(15.00, repayments[1][2], 0.001)

      assert_equal(@person3, repayments[2][0])
      assert_equal(@person1, repayments[2][1])
      assert_in_delta(5.00, repayments[2][2], 0.001)
    end
    
    def teardown
      @apportioner = nil
      @balances = nil
      @person1 = nil
      @person0 = nil
    end
  end
end
