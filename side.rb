#!/usr/bin/env ruby
module Hive
    class Side
        # The @bug class variable will be read/write, that's why it's declared with attr_accessor
        attr_accessor :bug
        # And these ones are read-only:
        attr_reader :id, :owner
        
        # Here are the constants we use to represent the sides of the hexagons. You'll see these show up elsewhere like Side::Face[:top_left].
        Face = { :top_left      => 0,
                 :top_center    => 1,
                 :top_right     => 2,
                 :bottom_right  => 3,
                 :bottom_center => 4,
                 :bottom_left   => 5,
                 :above         => 6,
                 :below         => 7}

        def initialize(id, owner); @owner, @bug, @id, @name = owner, false, id, Side::name?(id); end
        
        # Is this side open? Return true if the @bug variable is false.
        def open?; return @bug == false; end

        # Who's hanging out here? Remember this is always in reference to another bug. So each bug has 6 Hive::Sides, and each side can have a @bug variable.
        def bug; return @bug; end

        # The next few methods make programming and debugging easier. For instance, with this to_s (to_string) method, we can just do: bug.sides.each{|side| puts side} and we'll get a nice label instead of an error saying objects of type Hive::Side can't be casted (converted) to text.
        def to_s; return "#{Side::name?(@id)} of #{self.owner?}"; end

        def owner?;
            return owner.color? << " " << owner.class.name << " (ID: " << (owner.id != false ? owner.id : false).to_s << ")";
        end

        # More helper methods. Notice these ones have self. prefixed to the method name? That's so we can call them statically, like Side::name? or Side::opposite?, just like I did with Bug::announce
        def self.name?(side)
            return case side when Side::Face[:top_left] then "top left"
                             when Side::Face[:top_center] then "top center"
                             when Side::Face[:top_right] then "top right"
                             when Side::Face[:bottom_right] then "bottom right"
                             when Side::Face[:bottom_center] then "bottom center"
                             when Side::Face[:bottom_left] then "bottom left" end
        end

        def self.opposite?(side)
            return case side when Side::Face[:top_left] then Side::Face[:bottom_right]
                             when Side::Face[:top_center] then Side::Face[:bottom_center]
                             when Side::Face[:top_right] then Side::Face[:bottom_left]
                             when Side::Face[:bottom_right] then Side::Face[:top_left]
                             when Side::Face[:bottom_center] then Side::Face[:top_center]
                             when Side::Face[:bottom_left] then Side::Face[:top_right] end
        end
    end
end