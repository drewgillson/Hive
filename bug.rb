#!/usr/bin/env ruby
module Hive
    module Bug
        attr_reader :sides, :id, :color
        attr_accessor :is_in_play

        def initialize(color, id = false)
            @color, @id, @is_in_play, @sides = color, id, false, Array.new
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
            @sides.each{|side|
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
        def to_s; return "#{self.color?} #{self.class.name} (ID: #{@id})"; end
        def to_str; return "#{self.color?} #{self.class.name} (ID: #{@id})"; end
        def color?; return @color.==(White) ? 'White' : 'Black'; end
        def is_in_play?; return @is_in_play; end

        def walk
            6.times{|i|
                unless $game.surface.walkable_bugs.include?(@sides[i].bug) && @sides[i].bug
                    $game.surface.walkable_bugs << @sides[i].bug
                    @sides[i].bug.walk
                end
            }
        end

        def disappear
            @old_sides = @sides
            @sides.each_with_index{|side, name|
                side.bug.sides[Side::opposite?(name)].bug = false if side.bug
            }
            @hidden = true
        end

        def appear
            @sides = @old_sides
            @sides.each_with_index{|side, name|
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

        def move(color, bug, destination_side)
            bug = $game.surface.bug(color, bug)
            destination = bug.sides[destination_side]
            begin
                if self.move_candidates.include? destination
                    @sides.each_with_index{|side, name|
                        side.bug.sides[Side::opposite?(name)].bug = false if side.bug != false
                        side.bug = false
                    }
                    bug.+(self, destination_side)
                    Bug::announce(bug, self, destination_side)
                    puts "#{$game.turn?} moved #{self} to the #{Side::name? destination_side} of #{bug}"
                else
                    raise Hive::HiveException, "#{$game.turn?}, that's not a legal move!", caller
                end
            rescue HiveException => e
                puts e.message
            end
        end

        def self.announce(bug, test_bug, name)
            if name == TopLeft
                bug.bottom_left.+(test_bug, TopCenter) 
                bug.top_center.+(test_bug, BottomLeft)
                bug.bottom_left.top_left.+(test_bug, TopRight)
                bug.top_center.top_left.+(test_bug, BottomCenter)
                bug.bottom_left.top_left.top_center.+(test_bug, BottomRight)
                bug.top_center.top_left.bottom_left.+(test_bug, BottomRight)
            elsif name == TopCenter
                bug.top_left.+(test_bug, BottomLeft)
                bug.top_right.+(test_bug, BottomRight)
                bug.top_right.top_center.+(test_bug, BottomLeft)
                bug.top_left.top_center.+(test_bug, BottomRight)
                bug.top_left.top_center.top_right.+(test_bug, BottomCenter)
                bug.top_right.top_center.top_left.+(test_bug, BottomCenter)
            elsif name == TopRight
                bug.top_center.+(test_bug, BottomRight)
                bug.bottom_right.+(test_bug, TopCenter)
                bug.top_center.top_right.+(test_bug, BottomCenter)
                bug.bottom_right.top_right.+(test_bug, TopLeft)
                bug.top_center.top_right.bottom_right.+(test_bug, BottomLeft)
                bug.bottom_right.top_right.top_center.+(test_bug, BottomLeft)
            elsif name == BottomRight
                bug.top_right.+(test_bug, BottomCenter)
                bug.bottom_center.+(test_bug, TopRight)
                bug.top_right.bottom_right.+(test_bug, BottomLeft)
                bug.bottom_center.bottom_right.+(test_bug, TopCenter)
                bug.top_right.bottom_right.bottom_center.+(test_bug, TopLeft)
                bug.bottom_center.bottom_right.top_right.+(test_bug, TopLeft)
            elsif name == BottomCenter
                bug.bottom_left.+(test_bug, BottomRight)
                bug.bottom_right.+(test_bug, BottomLeft)
                bug.bottom_left.bottom_center.+(test_bug, TopRight)
                bug.bottom_right.bottom_center.+(test_bug, TopLeft)
                bug.bottom_left.bottom_center.bottom_right.+(test_bug, TopCenter)
                bug.bottom_right.bottom_center.bottom_left.+(test_bug, TopCenter)
            elsif name == BottomLeft
                bug.top_left.+(test_bug, BottomCenter)
                bug.bottom_center.+(test_bug, TopLeft)
                bug.top_left.bottom_left.+(test_bug, BottomRight)
                bug.bottom_center.bottom_left.+(test_bug, TopCenter)
                bug.top_left.bottom_left.bottom_center.+(test_bug, TopRight)
                bug.bottom_center.bottom_left.top_left.+(test_bug, TopRight)
            end   
        end
    end

    class Tester
        include Bug

        def legal_placement?
            @sides.each{|side| return false if side.bug != false && side.bug.color? != self.color? }
            return true
        end
    end

    class Ant
        include Bug

        def move_candidates            
            return nil if self.can_move? == false
            echo = caller[0].include? 'play'

            def ant_walk(bugs)
                @candidates = Array.new([bugs]) if @candidates.instance_of?(Array) == false
                @candidates.each{|bug|
                    6.times{|i|
                        unless @candidates.include?(bug.sides[i].bug) || bug.sides[i].bug == false
                            @candidates << bug.sides[i].bug
                        end
                    }
                }
                puts $game.white.count
                puts $game.black.count
                puts @candidates.count
                #return self.ant_walk(additions)
                return @candidates
            end

            return ant_walk(self)
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

        def move_candidates            
            return nil if self.can_move? == false
            echo = caller[0].include? 'play'

            @candidates = Array.new
            @sides.each_with_index{|side, name|
                move_candidate = side.bug
                if move_candidate != false
                    until move_candidate.sides[name].bug == false do
                        move_candidate = move_candidate.sides[name].bug
                    end
                    if echo
                        puts "#{$game.turn?}, you can move " + self + " to the " + Side::name?(name) + " of " +move_candidate.to_s
                    else
                        @candidates << move_candidate.sides[name]
                    end
                end
            }
            return @candidates
        end
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

        def is_surrounded?; @sides.each{|side| return false if side.bug == false}; end
    end
end