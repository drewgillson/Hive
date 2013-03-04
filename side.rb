#!/usr/bin/env ruby
module Hive
    class Side
        attr_accessor :bug
        attr_reader :id, :owner
        
        Face = { :top_left      => 0,
                 :top_center    => 1,
                 :top_right     => 2,
                 :bottom_right  => 3,
                 :bottom_center => 4,
                 :bottom_left   => 5,
                 :above         => 6,
                 :below         => 7}

        def initialize(id, owner); @owner, @bug, @id, @name = owner, false, id, Side::name?(id); end
        def open?; return @bug == false; end
        def bug; return @bug; end
        def to_s; return "#{Side::name?(@id)} of #{self.owner?}"; end

        def owner?;
            return owner.color? << " " << owner.class.name << " (ID: " << (owner.id != false ? owner.id : false).to_s << ")";
        end

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