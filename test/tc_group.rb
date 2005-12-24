require 'tc_person_set'

module TestKitty
  class TestGroup < TestPersonSet
    def setup
      @group = Kitty::Group.new('Test')
      @set = @group
    end

    def test_initial_state
      super
      assert_equal('Test', @group.name)
    end

    def test_no_name
      assert_raise(ArgumentError) {
        Kitty::Group.new(nil)
      }
      assert_raise(ArgumentError) {
        Kitty::Group.new('')
      }
    end

    def teardown
      super
      @group = nil
    end
  end
end