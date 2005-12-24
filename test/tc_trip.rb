require 'tc_person_set'
require 'date'

module TestKitty
  class TestTrip < TestPersonSet
    def setup
      @trip = Kitty::Trip.new('Test')
      @set = @trip
    end

    def test_initial_state
      super
      assert_equal('Test', @trip.name)
      assert_nil(@trip.period)
    end

    def test_period
      period = Date.new(2005, 9, 10)..Date.new(2005, 9, 25)
      @trip = Kitty::Trip.new('Test', period)
      assert_equal('Test', @trip.name)
      assert_same(period, @trip.period)
    end

    def test_no_name
      assert_raise(ArgumentError) {
        Kitty::Trip.new(nil)
      }
      assert_raise(ArgumentError) {
        Kitty::Trip.new('')
      }
    end

    def teardown
      super
      @trip = nil
    end
  end
end