#!/usr/bin/env ruby
module Hive
    class Side
        attr_accessor :bug
        attr_reader :id
        
        def initialize(id, owner); @owner, @bug, @id, @name = owner, false, id, Side::name?(id); end
        def open?; return @bug == false; end
        def bug; return @bug; end
        def to_s; return "#{Side::name?(@id)} of #{self.owner?}"; end

        def owner?;
            return owner.color? << " " << owner.class.name << " (ID: " << (owner.id != false ? owner.id : false).to_s << ")";
        end

        def self.name?(side)
            return case side when TopLeft then "TopLeft"
                             when TopCenter then "TopCenter"
                             when TopRight then "TopRight"
                             when BottomRight then "BottomRight"
                             when BottomCenter then "BottomCenter"
                             when BottomLeft then "BottomLeft" end
        end

        def self.opposite?(side)
            return case side when TopLeft then BottomRight
                             when TopCenter then BottomCenter
                             when TopRight then BottomLeft
                             when BottomRight then TopLeft
                             when BottomCenter then TopCenter
                             when BottomLeft then TopRight end
        end
    end
end