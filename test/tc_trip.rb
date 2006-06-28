require 'tc_person_set'

module TestKitty
  class TestTrip < TestPersonSet
    def setup
      @trip = Kitty::Trip.new('Test')
      @set = @trip
    end

    def test_initial_state
      super
      assert_equal('Test', @trip.name)
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
