#!/usr/bin/env ruby
module Hive
    class Ant
        include Bug

        def move_candidates            
            return nil if self.can_move? == false
            echo = caller[0].include? 'play'

=begin
            # This is a way to limit the problem space so we reduce recursion in ant_walk
            @i = $game.surface.bugs_in_play?.count * 6

            def ant_walk(sides)
                sides.each_with_index{|side,name|
                    @i = @i - 1
                    @candidates << side if side.bug == false && @candidates.include?(side) == false
                }
                self.ant_walk(@candidates) if @i > 0
                return @candidates
            end

            return ant_walk(self.sides)
=end
        end

        def move; end
    end
end