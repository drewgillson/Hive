#!/usr/bin/env ruby
module Hive
    module Bug
        attr_reader :sides, :id, :color
        attr_accessor :is_in_play

        # Here are the constants we use to keep track of the bugs a little bit more easily. Because these correspond to IDs, and Hive::Surface.bug takes a color and an ID, we can do this to get a black spider: $game.surface.bug(Black,spider1)
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
            # This is an elegant way to create six new Hive::Side objects and stuff them into an array that belongs to this bug. Because the @sides variable starts with an @, it is accessible anywhere else in this class (but not outside of it, unless we have defined an attr_reader or attr_accessor like I have above).
            6.times{|i| @sides << Side.new(i, self)}
        end

        # The + method is a notification method that gets called whenever a bug lands next to another bug. The bugs have to let each other know they're next to one another.
        def +(bug, side) # side is one of the Side::Face constants in side.rb
            # Remember because we're IN A BUG RIGHT NOW, that @sides refers to MY sides. So if the value of side is top_left, I'm registering the fact that there is now a new bug on my top left.
            @sides[side].bug = bug
            # Vice-versa, I have to tell the other bug that I'm on his bottom right. We can do that using the helper method Side::opposite?
            bug.sides[Side::opposite?(side)].bug = self # Self is the instance of this class
            return "#{$game.turn?} placed #{bug} in #{Side::name? side} of #{self}"
        end

        # It's considered good practice to make helpful methods like this rather than having a read/write variable that anyone can change the value of. Ruby allows you to add a ? to the end of method names which makes a lot of sense!
        def not_hidden?; return !@hidden; end
        def color?; return @color.==(Hive::Color[:white]) ? 'White' : 'Black'; end
        def is_in_play?; return @is_in_play; end

        # These are all helper functions to quickly get the bug objects that are adjacent to me
        def top_left; return @sides[Side::Face[:top_left]].bug if @sides[Side::Face[:top_left]].bug != false; end
        def top_center; return @sides[Side::Face[:top_center]].bug if @sides[Side::Face[:top_center]].bug != false; end
        def top_right; return @sides[Side::Face[:top_right]].bug if @sides[Side::Face[:top_right]].bug != false; end
        def bottom_left; return @sides[Side::Face[:bottom_left]].bug if @sides[Side::Face[:bottom_left]].bug != false; end
        def bottom_center; return @sides[Side::Face[:bottom_center]].bug if @sides[Side::Face[:bottom_center]].bug != false; end
        def bottom_right; return @sides[Side::Face[:bottom_right]].bug if @sides[Side::Face[:bottom_right]].bug != false; end
        
        # More helper functions for pretty-printed debugging
        def to_s; return "#{self.color?} #{self.class.name} (ID: #{@id})"; end
        def to_str; return "#{self.color?} #{self.class.name} (ID: #{@id})"; end

        # This is the complement to the Surface::walk method that calls this method on a single bug, which then triggers the same method to be called on every bug it's is touching.
        def walk(look_for_sides = false)
            @sides.each{|side|
                if side.bug
                    # The "unless" control structure is really unique. Most people never use much but if/else. What's happening here is that if the array called walkable_bugs that lives in the $game.surface object (an instance of the Hive::Surface class) already contains a side.bug, this code won't get executed.
                    unless $game.surface.walkable_bugs.include?(side.bug)
                        $game.surface.walkable_bugs << side.bug
                        side.bug.sides.each{|side| $game.surface.open_sides << side } if look_for_sides
                        side.bug.walk(look_for_sides)
                    end
                end
            }
        end

        # This is a helper method that describes what's around this bug
        def describe
            puts "\nThis is what's around " << self
            @sides.each{|side|
                puts "    " << side.bug << " is in " << Side::name?(side.id) if side.bug != false
                puts "    " << Side::name?(side.id) << " is open " if side.bug == false
            }
        end

        # These appear and disappear methods are used when testing to see if a given bug can move. See the Surface::walk method and the can_move? method below for a better explanation. They are also stubs to be used for implementing the Beetle.
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

        # To see if a bug can move, we get a count of the "walkable" bugs, then we disappear, then we get a second count. If the counts match, we weren't integral to the hive.
        def can_move?
            walkable_count = $game.surface.walk.count - 1
            self.disappear
            walkable_count_after_disappear = $game.surface.walk.count
            self.appear
            return walkable_count == walkable_count_after_disappear
        end

        # This moves a bug to a new spot in the hive. It depends on the move_candidates method which  differs from bug to bug.
        def move(color, bug, destination_side)
            destination = $game.surface.bug(color, bug).sides[destination_side]
            begin
                # If our destination is in the list of "move candidates" we can proceed
                if self.move_candidates.include?(destination.to_s) || self.move_candidates.include?(destination)

                    # Let our neighbors know we're leaving
                    @sides.each{|side|
                        side.bug.sides[Side::opposite?(side.id)].bug = false if side.bug != false
                        side.bug = false
                    }

                    # And say what's up to our new bug neighbors!
                    $game.surface.bug(color, bug).+(self, destination_side)
                    Bug::announce($game.surface.bug(color, bug), self, destination_side)

                    puts "#{$game.turn?} moved #{self} to the #{Side::name? destination_side} of " << $game.surface.bug(color, bug).to_s

                    $game.next_turn
                else
                    raise Hive::HiveException, "#{$game.turn?}, that's not a legal move!", caller
                end
            rescue HiveException => e
                puts e.message
            end
        end

        # Kudos to Dominique for helping me out with this one. The new_bug is going into the reference_bug's position, so therefore we have to let the reference bug's neighbors know that there's a new bug around. But where the new bug is in relation to them is tricky - we have to walk our way around in a circle to make sure everyone who could possible be touching the new bug knows about it.
        def self.announce(reference_bug, new_bug, position)
            if position == Side::Face[:top_left]
                reference_bug.bottom_left.+(new_bug, Side::Face[:top_center]) 
                reference_bug.top_center.+(new_bug, Side::Face[:bottom_left])
                reference_bug.bottom_left.top_left.+(new_bug, Side::Face[:top_right])
                reference_bug.top_center.top_left.+(new_bug, Side::Face[:bottom_center])
                # For instance, if we placed ourselves on the top left of the reference bug, we need to let the bug on his bottom left let the bug on his top left let the bug on his top center know that there's a new bug on HIS bottom right!
                reference_bug.bottom_left.top_left.top_center.+(new_bug, Side::Face[:bottom_right])
                reference_bug.top_center.top_left.bottom_left.+(new_bug, Side::Face[:bottom_right])

            elsif position == Side::Face[:top_center]
                reference_bug.top_left.+(new_bug, Side::Face[:top_right])
                reference_bug.top_right.+(new_bug, Side::Face[:top_left])
                reference_bug.top_left.top_center.+(new_bug, Side::Face[:bottom_right])
                reference_bug.top_right.top_center.+(new_bug, Side::Face[:bottom_left])
                reference_bug.top_left.top_center.top_right.+(new_bug, Side::Face[:bottom_center])
                reference_bug.top_right.top_center.top_left.+(new_bug, Side::Face[:bottom_center])

            elsif position == Side::Face[:top_right]
                reference_bug.top_center.+(new_bug, Side::Face[:bottom_right])
                reference_bug.bottom_right.+(new_bug, Side::Face[:top_center])
                reference_bug.top_center.top_right.+(new_bug, Side::Face[:bottom_center])
                reference_bug.bottom_right.top_right.+(new_bug, Side::Face[:top_left])
                reference_bug.top_center.top_right.bottom_right.+(new_bug, Side::Face[:bottom_left])
                reference_bug.bottom_right.top_right.top_center.+(new_bug, Side::Face[:bottom_left])

            elsif position == Side::Face[:bottom_right]
                reference_bug.top_right.+(new_bug, Side::Face[:bottom_center])
                reference_bug.bottom_center.+(new_bug, Side::Face[:top_right])
                reference_bug.top_right.bottom_right.+(new_bug, Side::Face[:bottom_left])
                reference_bug.bottom_center.bottom_right.+(new_bug, Side::Face[:top_center])
                reference_bug.top_right.bottom_right.bottom_center.+(new_bug, Side::Face[:top_left])
                reference_bug.bottom_center.bottom_right.top_right.+(new_bug, Side::Face[:top_left])

            elsif position == Side::Face[:bottom_center]
                reference_bug.bottom_left.+(new_bug, Side::Face[:bottom_right])
                reference_bug.bottom_right.+(new_bug, Side::Face[:bottom_left])
                reference_bug.bottom_left.bottom_center.+(new_bug, Side::Face[:top_right])
                reference_bug.bottom_right.bottom_center.+(new_bug, Side::Face[:top_left])
                reference_bug.bottom_left.bottom_center.bottom_right.+(new_bug, Side::Face[:top_center])
                reference_bug.bottom_right.bottom_center.bottom_left.+(new_bug, Side::Face[:top_center])

            elsif position == Side::Face[:bottom_left]
                reference_bug.top_left.+(new_bug, Side::Face[:bottom_center])
                reference_bug.bottom_center.+(new_bug, Side::Face[:top_left])
                reference_bug.top_left.bottom_left.+(new_bug, Side::Face[:bottom_right])
                reference_bug.bottom_center.bottom_left.+(new_bug, Side::Face[:top_center])
                reference_bug.top_left.bottom_left.bottom_center.+(new_bug, Side::Face[:top_right])
                reference_bug.bottom_center.bottom_left.top_left.+(new_bug, Side::Face[:top_right])
            end   
        end
    end

    # This includes the bug-specific classes in the /bugs folder
    require_relative 'bugs/tester'
    require_relative 'bugs/ant'
    require_relative 'bugs/beetle'
    require_relative 'bugs/spider'
    require_relative 'bugs/grasshopper'
    require_relative 'bugs/mosquito'
    require_relative 'bugs/ladybug'
    require_relative 'bugs/queen'
end