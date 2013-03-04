#!/usr/bin/env ruby
module Hive
    class Tester
        include Bug

        # Are we touching any colors that aren't our own color?
        def legal_placement?
            @sides.each{|side| return false if side.bug != false && side.bug.color? != self.color? }
            return true
        end
    end
end