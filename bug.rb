#!/usr/bin/env ruby
module Hive
    module Bug
        attr_reader :sides, :id, :color
        attr_accessor :is_in_play

        Type = { :ant1         => 0,
                 :ant2         => 1,
                 :ant3         => 2,
                 :grasshopper1 => 3,
                 :grasshopper2 => 4,
                 :grasshopper3 => 5,
                 :spider1      => 6,
                 :spider2      => 7,
                 :beetle1      => 8,
                 :beetle2      => 9,
                 :ladybug1     => 10,
                 :mosquito1    => 11,
                 :queen1       => 12}

        def initialize(color, id = false)
            @color, @id, @is_in_play, @sides, @candidates = color, id, false, Array.new, Array.new
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

        def top_left; return @sides[Side::Face[:top_left]].bug if @sides[Side::Face[:top_left]].bug != false; end
        def top_center; return @sides[Side::Face[:top_center]].bug if @sides[Side::Face[:top_center]].bug != false; end
        def top_right; return @sides[Side::Face[:top_right]].bug if @sides[Side::Face[:top_right]].bug != false; end
        def bottom_left; return @sides[Side::Face[:bottom_left]].bug if @sides[Side::Face[:bottom_left]].bug != false; end
        def bottom_center; return @sides[Side::Face[:bottom_center]].bug if @sides[Side::Face[:bottom_center]].bug != false; end
        def bottom_right; return @sides[Side::Face[:bottom_right]].bug if @sides[Side::Face[:bottom_right]].bug != false; end
        def to_s; return "#{self.color?} #{self.class.name} (ID: #{@id})"; end
        def to_str; return "#{self.color?} #{self.class.name} (ID: #{@id})"; end
        def color?; return @color.==(Hive::Color[:white]) ? 'White' : 'Black'; end
        def is_in_play?; return @is_in_play; end

        def walk(look_for_sides = false)
            @sides.each{|side|
                if side.bug
                    unless $game.surface.walkable_bugs.include?(side.bug)
                        $game.surface.walkable_bugs << side.bug
                        side.bug.sides.each{|side| $game.surface.open_sides << side } if look_for_sides
                        side.bug.walk(look_for_sides)
                    end
                end
            }
        end

        def describe
            puts "\nThis is what's around " << self
            @sides.each{|side|
                puts "    " << side.bug << " is in " << Side::name?(side.id) if side.bug != false
                puts "    " << Side::name?(side.id) << " is open " if side.bug == false
            }
        end

        def disappear
            @old_sides = @sides
            @sides.each{|side|
                side.bug.sides[Side::opposite?(side.id)].bug = false if side.bug
            }
            @hidden = true
        end

        def appear
            @sides = @old_sides
            @sides.each{|side|
                side.bug.sides[Side::opposite?(side.id)].bug = self if side.bug
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

        def move(color, bug, destination_side)
            bug = $game.surface.bug(color, bug)
            destination = bug.sides[destination_side]
            begin
                if self.move_candidates.include?(destination.to_s) || self.move_candidates.include?(destination)
                    @sides.each{|side|
                        side.bug.sides[Side::opposite?(side.id)].bug = false if side.bug != false
                        side.bug = false
                    }
                    bug.+(self, destination_side)
                    $game.surface.bug(Hive::Color[:black], Bug::Type[:queen1]).describe

                    Bug::announce(bug, self, destination_side)

                    puts "#{$game.turn?} moved #{self} to the #{Side::name? destination_side} of #{bug}"

                    $game.next_turn
                else
                    puts self.move_candidates
                    puts "114:"
                    puts destination
                    raise Hive::HiveException, "#{$game.turn?}, that's not a legal move!", caller
                end
            rescue HiveException => e
                puts e.message
            end
        end

        def self.announce(bug, test_bug, name)
            if name == Side::Face[:top_left]
                bug.bottom_left.+(test_bug, Side::Face[:top_center]) 
                bug.top_center.+(test_bug, Side::Face[:bottom_left])
                bug.bottom_left.top_left.+(test_bug, Side::Face[:top_right])
                bug.top_center.top_left.+(test_bug, Side::Face[:bottom_center])
                bug.bottom_left.top_left.top_center.+(test_bug, Side::Face[:bottom_right])
                bug.top_center.top_left.bottom_left.+(test_bug, Side::Face[:bottom_right])
            elsif name == Side::Face[:top_center]
                bug.top_left.+(test_bug, Side::Face[:bottom_left])
                bug.top_right.+(test_bug, Side::Face[:bottom_right])
                bug.top_right.top_center.+(test_bug, Side::Face[:bottom_left])
                bug.top_left.top_center.+(test_bug, Side::Face[:bottom_right])
                bug.top_left.top_center.top_right.+(test_bug, Side::Face[:bottom_center])
                bug.top_right.top_center.top_left.+(test_bug, Side::Face[:bottom_center])
            elsif name == Side::Face[:top_right]
                bug.top_center.+(test_bug, Side::Face[:bottom_right])
                bug.bottom_right.+(test_bug, Side::Face[:top_center])
                bug.top_center.top_right.+(test_bug, Side::Face[:bottom_center])
                bug.bottom_right.top_right.+(test_bug, Side::Face[:top_left])
                bug.top_center.top_right.bottom_right.+(test_bug, Side::Face[:bottom_left])
                bug.bottom_right.top_right.top_center.+(test_bug, Side::Face[:bottom_left])
            elsif name == Side::Face[:bottom_right]
                bug.top_right.+(test_bug, Side::Face[:bottom_center])
                bug.bottom_center.+(test_bug, Side::Face[:top_right])
                bug.top_right.bottom_right.+(test_bug, Side::Face[:bottom_left])
                bug.bottom_center.bottom_right.+(test_bug, Side::Face[:top_center])
                bug.top_right.bottom_right.bottom_center.+(test_bug, Side::Face[:top_left])
                bug.bottom_center.bottom_right.top_right.+(test_bug, Side::Face[:top_left])
            elsif name == Side::Face[:bottom_center]
                bug.bottom_left.+(test_bug, Side::Face[:bottom_right])
                bug.bottom_right.+(test_bug, Side::Face[:bottom_left])
                bug.bottom_left.bottom_center.+(test_bug, Side::Face[:top_right])
                bug.bottom_right.bottom_center.+(test_bug, Side::Face[:top_left])
                bug.bottom_left.bottom_center.bottom_right.+(test_bug, Side::Face[:top_center])
                bug.bottom_right.bottom_center.bottom_left.+(test_bug, Side::Face[:top_center])
            elsif name == Side::Face[:bottom_left]
                bug.top_left.+(test_bug, Side::Face[:bottom_center])
                bug.bottom_center.+(test_bug, Side::Face[:top_left])
                bug.top_left.bottom_left.+(test_bug, Side::Face[:bottom_right])
                bug.bottom_center.bottom_left.+(test_bug, Side::Face[:top_center])
                bug.top_left.bottom_left.bottom_center.+(test_bug, Side::Face[:top_right])
                bug.bottom_center.bottom_left.top_left.+(test_bug, Side::Face[:top_right])
            end   
        end
    end

    require_relative 'bugs/tester'
    require_relative 'bugs/ant'
    require_relative 'bugs/beetle'
    require_relative 'bugs/spider'
    require_relative 'bugs/grasshopper'
    require_relative 'bugs/mosquito'
    require_relative 'bugs/ladybug'
    require_relative 'bugs/queen'
end