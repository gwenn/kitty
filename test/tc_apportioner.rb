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
      creditors = nil
      repayments = nil
      debitors = nil
      assert_nothing_raised {
        creditors, repayments, debitors = @apportioner.distribute(@balances)
      }
      assert_nil(creditors)
      assert_nil(repayments)
      assert_nil(debitors)
    end

    def test_distribute
      @balances[@person0] = 5
      @balances[@person1] = -5
      creditors, repayments, debitors = @apportioner.distribute(@balances)
      assert_equal(1, creditors.length)
      assert_equal(@person0, creditors[0])
      assert_equal(1, debitors.length)
      assert_equal(@person1, debitors[0])
      assert_equal(1, repayments.length)
      assert_equal([[5]], repayments[0])
    end

    def test_distribute_order
      @balances[@person0] = 25
      @balances[@person1] = 10
      @balances[@person2] = -15
      @balances[@person3] = -20
      creditors, repayments, debitors = @apportioner.distribute(@balances)
      assert_equal(2, creditors.length)
      assert_equal(@person0, creditors[0])
      assert_equal(@person1, creditors[1])
      assert_equal(2, debitors.length)
      assert_equal(@person2, debitors[0])
      assert_equal(@person3, debitors[1])
      assert_equal(2, repayments.length)
      assert_equal([[15, 10], [0, 10]], repayments[0])
      assert_equal([[5, 20], [10, 0]], repayments[1])
    end

    def test_distribute_with_prefer_to_pay_back
      @person2.prefer_to_pay_back(@person1)
      @balances[@person0] = 15
      @balances[@person1] = 15
      @balances[@person2] = -10
      @balances[@person3] = -20
      creditors, repayments, debitors = @apportioner.distribute(@balances)
      assert_equal(2, creditors.length)
      assert_equal(@person0, creditors[0])
      assert_equal(@person1, creditors[1])
      assert_equal(2, debitors.length)
      assert_equal(@person2, debitors[0])
      assert_equal(@person3, debitors[1])
      assert_equal(1, repayments.length)
      assert_equal([[0, 15], [10, 5]], repayments[0])
    end
    
    def teardown
      @apportioner = nil
      @balances = nil
      @person1 = nil
      @person0 = nil
    end

    private
    def assert_amount(expected, actual)
      assert(Kitty::Payment.to_i(expected), actual)
    end
  end
end
