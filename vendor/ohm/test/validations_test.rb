require File.expand_path(File.join(File.dirname(__FILE__), "test_helper"))

class ValidationsTest < Test::Unit::TestCase
  class Event < Ohm::Model
    attribute :name
    attribute :place
    attribute :capacity

    index :name
    index :place

    def validate
      assert_format(:name, /^\w+$/)
    end
  end

  context "A new model with validations" do
    setup do
      @event = Event.new
    end

    context "That must have a present name" do
      should "not be created if the name is never assigned" do
        @event.create
        assert @event.new?
      end

      should "not be created if the name assigned is empty" do
        @event.name = ""
        @event.create
        assert @event.new?
      end

      should "be created if the name assigned is not empty" do
        @event.name = "hello"
        @event.create
        assert_not_nil @event.id
      end

      context "And must have a name with only \w+" do
        should "not be created if the name doesn't match /^\w+$/" do
          @event.name = "hello-world"
          @event.create
          assert @event.new?
        end
      end
    end

    context "That must have a numeric attribute :capacity" do
      should "fail when the value is nil" do
        def @event.validate
          assert_numeric :capacity
        end

        @event.name = "foo"
        @event.place = "bar"
        @event.create

        assert @event.new?
        assert_equal [[:capacity, :not_numeric]], @event.errors
      end

      should "fail when the value is not numeric" do
        def @event.validate
          assert_numeric :capacity
        end

        @event.name = "foo"
        @event.place = "bar"
        @event.capacity = "baz"
        @event.create

        assert @event.new?
        assert_equal [[:capacity, :not_numeric]], @event.errors
      end

      should "succeed when the value is numeric" do
        def @event.validate
          assert_numeric :capacity
        end

        @event.name = "foo"
        @event.place = "bar"
        @event.capacity = 42
        @event.create

        assert_not_nil @event.id
      end
    end

    context "That must have a unique name" do
      should "fail when the value already exists" do
        def @event.validate
          assert_unique :name
        end

        Event.create(:name => "foo")
        @event.name = "foo"
        @event.create

        assert @event.new?
        assert_equal [[:name, :not_unique]], @event.errors
      end
    end

    context "That must have a unique name scoped by place" do
      should "fail when the value already exists for a scoped attribute" do
        def @event.validate
          assert_unique [:name, :place]
        end

        Event.create(:name => "foo", :place => "bar")
        @event.name = "foo"
        @event.place = "bar"
        @event.create

        assert @event.new?
        assert_equal [[[:name, :place], :not_unique]], @event.errors

        @event.place = "baz"
        @event.create

        assert @event.valid?
      end
    end

    context "That defines a unique validation on a non indexed attribute" do
      should "raise ArgumentError" do
        def @event.validate
          assert_unique :capacity
        end

        assert_raises(Ohm::Model::IndexNotFound) do
          @event.valid?
        end
      end
    end
  end

  context "An existing model with a valid name" do
    setup do
      @event = Event.create(:name => "original")
    end

    context "That has the name changed" do
      should "not be saved if the new name is nil" do
        @event.name = nil
        @event.save
        assert_equal false, @event.valid?
        assert_equal "original", Event[@event.id].name
      end

      should "not be saved if the name assigned is empty" do
        @event.name = ""
        @event.save
        assert_equal false, @event.valid?
        assert_equal "original", Event[@event.id].name
      end

      should "be saved if the name assigned is not empty" do
        @event.name = "hello"
        @event.save
        assert @event.valid?
        assert_equal "hello", Event[@event.id].name
      end
    end
  end

  context "Validations module" do
    class Validatable
      attr_accessor :name

      include Ohm::Validations
    end

    setup do
      @target = Validatable.new
    end

    context "assert" do
      should "add errors to a collection" do
        def @target.validate
          assert(false, "Something bad")
        end

        @target.validate

        assert_equal ["Something bad"], @target.errors
      end

      should "allow for nested validations" do
        def @target.validate
          if assert(true, "No error")
            assert(false, "Chained error")
          end

          if assert(false, "Parent error")
            assert(false, "No chained error")
          end
        end

        @target.validate

        assert_equal ["Chained error", "Parent error"], @target.errors
      end
    end

    context "assert_present" do
      setup do
        def @target.validate
          assert_present(:name)
        end
      end

      should "fail when the attribute is nil" do
        @target.validate

        assert_equal [[:name, :not_present]], @target.errors
      end

      should "fail when the attribute is empty" do
        @target.name = ""
        @target.validate

        assert_equal [[:name, :not_present]], @target.errors
      end
    end
  end
end
