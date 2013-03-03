#!/usr/bin/env ruby
module Hive
    module Bug
        attr_accessor :sides, :is_in_play, :id, :color

        def initialize(color, id = false)
            @color = color
            @id = id
            @is_in_play = false
            @sides = Array.new
            6.times{|i| @sides << Side.new(i, self)}
        end

        def +(bug, side)
            @sides[side].bug = bug
            bug.sides[Side::opposite?(side)].bug = self
            return "#{$game.turn?} placed #{bug} in #{Side::name? side} of #{self}"
        end

        def not_hidden?
            return !@hidden
        end

        def open_sides?
            open_sides = Array.new
            @sides.each{|side| open_sides << side if side.open?}
            return open_sides.count
        end

        def describe
            puts "\nThis is what's around " << self
            self.sides.each{|side|
                puts "    " << side.bug << " is in " << Side::name?(side.id) if side.bug != false
                puts "    " << Side::name?(side.id) << " is open " if side.bug == false
            }
        end

        def top_left; return @sides[TopLeft].bug if @sides[TopLeft].bug != false; end
        def top_center; return @sides[TopCenter].bug if @sides[TopCenter].bug != false; end
        def top_right; return @sides[TopRight].bug if @sides[TopRight].bug != false; end
        def bottom_left; return @sides[BottomLeft].bug if @sides[BottomLeft].bug != false; end
        def bottom_center; return @sides[BottomCenter].bug if @sides[BottomCenter].bug != false; end
        def bottom_right; return @sides[BottomRight].bug if @sides[BottomRight].bug != false; end
        def to_s; return "#{self.color?} #{self.class.name} (ID: #{self.id})"; end
        def to_str; return "#{self.color?} #{self.class.name} (ID: #{self.id})"; end
        def color?; return @color.==(White) ? 'White' : 'Black'; end
        def is_in_play?; return @is_in_play; end

        def walk
            6.times{|i|
                if @sides[i-1].bug
                    unless $game.surface.walkable_bugs.include?(@sides[i-1].bug)
                        $game.surface.walkable_bugs << @sides[i-1].bug
                        @sides[i-1].bug.walk
                    end
                end
            }
        end

        def disappear
            @old_sides = @sides
            self.sides.each_with_index{|side, name|
                side.bug.sides[Side::opposite?(name)].bug = false if side.bug
            }
            @hidden = true
        end

        def appear
            @sides = @old_sides
            self.sides.each_with_index{|side, name|
                side.bug.sides[Side::opposite?(name)].bug = self if side.bug
            }
            @hidden = false
        end

        def can_move?
            walkable_count = $game.surface.walk.count - 1
            self.disappear
            walkable_count_after_disappear = $game.surface.walk.count
            self.appear
            return walkable_count == walkable_count_after_disappear
        end

        def move; end
    end

    class Tester
        include Bug

        def legal_placement?
            self.sides.each{|side|
                return false if side.bug != false && side.bug.color? != self.color?
            }
            return true
        end
    end

    class Ant
        include Bug

        def move_candidates
            puts self.can_move?
        end

        def move; end
    end

    class Beetle
        include Bug

        def move; end
    end

    class Spider
        include Bug

        def move; end
    end

    class Grasshopper
        include Bug

        def move; end
    end

    class Mosquito
        include Bug

        def move; end
    end

    class Ladybug
        include Bug

        def move; end
    end

    class Queen
        include Bug

        def move; end

        def is_surrounded?; self.sides.each{|side| return false if side.bug == false}; end
    end
end