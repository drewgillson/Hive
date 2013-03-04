#!/usr/bin/env ruby
module Hive
    Color = {:white => 0, :black => 1}

    class Game
        # These are all the variables we want the Game class to share with other objects:
        attr_accessor :trays,
                      :bugs,
                      :surface,
                      :turn,
                      :turn_number

        # For the time being this is how a game is "played". More detail on the surface method and the + sign method in the surface.rb file.
        def play
            $game.surface.+$game.white.get('Ant')
            $game.surface.+$game.black.get('Beetle')
            $game.surface.+($game.white.get('Ant'), $game.surface.bug(Hive::Color[:white], Bug::Type[:ant1]), Side::Face[:bottom_left])
            #$game.surface.+($game.black.get('Grasshopper'), $game.surface.bug(Hive::Color[:black], Bug::Type[:beetle1]), Side::Face[:bottom_left])
            $game.surface.+($game.black.get('Grasshopper'), $game.surface.bug(Hive::Color[:black], Bug::Type[:beetle1]), Side::Face[:top_right])
            $game.surface.+($game.white.get('Ant'), $game.surface.bug(Hive::Color[:white], Bug::Type[:ant2]), Side::Face[:bottom_right])
            $game.surface.+($game.black.get('Queen'), $game.surface.bug(Hive::Color[:black], Bug::Type[:grasshopper1]), Side::Face[:top_right])
            $game.surface.+($game.white.get('Queen'), $game.surface.bug(Hive::Color[:white], Bug::Type[:ant3]), Side::Face[:bottom_right])
            $game.surface.+($game.black.get('Grasshopper'), $game.surface.bug(Hive::Color[:black], Bug::Type[:queen1]), Side::Face[:top_right])
            $game.surface.+($game.white.get('Spider'), $game.surface.bug(Hive::Color[:white], Bug::Type[:queen1]), Side::Face[:bottom_center])
            $game.surface.bug(Hive::Color[:black], Bug::Type[:grasshopper2]).move(Hive::Color[:black], Bug::Type[:beetle1], Side::Face[:bottom_left])
            $game.surface.bug(Hive::Color[:white], Bug::Type[:ant2]).move(Hive::Color[:black], Bug::Type[:queen1], Side::Face[:bottom_center])
            $game.surface.+($game.black.get('Grasshopper'), $game.surface.bug(Hive::Color[:black], Bug::Type[:beetle1]), Side::Face[:top_center])
            
            # Try putting a $game.list_moves after any move directive

            puts "\n\n=====PROOF SECTION======================="
            $game.surface.bug(Hive::Color[:black], Bug::Type[:beetle1]).describe
            $game.surface.bug(Hive::Color[:black], Bug::Type[:grasshopper1]).describe
            $game.surface.bug(Hive::Color[:black], Bug::Type[:grasshopper2]).describe
            $game.surface.bug(Hive::Color[:black], Bug::Type[:grasshopper3]).describe
            $game.surface.bug(Hive::Color[:black], Bug::Type[:queen1]).describe
            
            $game.surface.bug(Hive::Color[:white], Bug::Type[:ant1]).describe
            $game.surface.bug(Hive::Color[:white], Bug::Type[:ant2]).describe
            $game.surface.bug(Hive::Color[:white], Bug::Type[:ant3]).describe
            $game.surface.bug(Hive::Color[:white], Bug::Type[:queen1]).describe
            $game.surface.bug(Hive::Color[:white], Bug::Type[:spider1]).describe
        end

        # The initialize method is an "automagic" method that gets called any time you create a new instance of a class, like on line 139 below.
        def initialize
            puts "\nWelcome to Hive!\n****************\n"

            @surface = Surface.new
            # This list-mapping syntax is probably the most confusing thing I've found about Ruby. Whenever you have things in square brackets they are automatically an Array class, so you have access to any of the array methods (http://www.ruby-doc.org/core-2.0/Array.html)
            @trays = [Hive::Color[:white], Hive::Color[:black]].collect {|tray| tray = Tray.new}
            @bugs =  [Hive::Color[:white], Hive::Color[:black]].collect {|tray| tray = Tray.new}
            # So [Red, Green, Blue].collect {|color| puts color} will print Red, Green, and Blue. In this case we are assigning the value of @trays[White], @trays[Black], @bugs[White], and @bugs[Black] to new instances of the Tray class.
            
            @turn_number = 1
            @turn = Hive::Color[:black]

            # We'll loop through to create our bugs. The << operator stuffs the thing on the right into the array on the left. In this case we are using a Ruby feature that allows us to "instantiate" a class of a given name by passing it into the const_get method, which is available in the Object class that everything in Ruby inherits from.
            2.times {
                        # @trays[@turn] becomes @trays[Black or White]
                3.times { @trays[@turn] << Hive.const_get('Ant').new(@turn, @trays[turn].count) }
                3.times { @trays[@turn] << Hive.const_get('Grasshopper').new(@turn, @trays[turn].count) }
                2.times { @trays[@turn] << Hive.const_get('Spider').new(@turn, @trays[turn].count) }
                2.times { @trays[@turn] << Hive.const_get('Beetle').new(@turn, @trays[turn].count) }
                1.times { @trays[@turn] << Hive.const_get('Ladybug').new(@turn, @trays[turn].count) }
                1.times { @trays[@turn] << Hive.const_get('Mosquito').new(@turn, @trays[turn].count) }
                1.times { @trays[@turn] << Hive.const_get('Queen').new(@turn, @trays[turn].count) }
                
                # When we get to the end of the black bugs we go back up to the top and do it all over again for the white ones.
                @turn = Hive::Color[:white]
            }
        end

        # Helper methods to get the white or black "tray" - the bugs that aren't on the game surface.
        def white; return self.trays[Hive::Color[:white]]; end
        def black; return self.trays[Hive::Color[:black]]; end

        # Whose turn is it?
        def turn?; return @turn == 0 ? 'White' : 'Black'; end

        # We call this at the start of a lot of other methods to make sure things don't happen out of sequence.
        def not_my_turn?(color)
            begin
                if self.turn == color
                    return false
                else
                    # When we "raise" or "throw" an exception, we are indicating that something unusual has happened that needs to be dealt with below.
                    raise HiveException, "#{color == Hive::Color[:white] ? "White" : "Black"}, it's not your turn!", caller
                end
            # If an exception gets thrown, we can do any required cleanup or messaging in a rescue block following the exception 
            rescue HiveException => e
                puts e.message
            end
            return true
        end

        # Advance the turn
        def next_turn
            $game.check_state
            $game.turn = ($game.turn == Hive::Color[:white] ? Hive::Color[:black] : Hive::Color[:white])
            $game.turn_number = $game.turn_number + 1
        end

        # List all available moves for the current turn
        def list_moves
            $game.surface.move_candidates($game.turn)
            puts "These are your open spots to place a new bug:\n"
            $game.surface.place_candidates($game.turn).each{|place|puts place}
        end

        # Has the game been won?
        def check_state
            [Hive::Color[:white],Hive::Color[:black]].collect{|color|
                abort("#{$game.turn?} won!") if self.trays[color].queen.is_surrounded?
            }
        end
    end

    # This is a class that is just like an array with a few extra features. It's used to hold the bugs that are not yet on the game surface.
    class Tray < Array
        
        # Get a particular bug from the tray
        def get(type)
            self.each{|bug| return bug if bug.class.name == "Hive::#{type}" && bug.is_in_play? == false}
            begin
                raise HiveException, "#{$game.turn?}, you have no more #{type}s in your tray"
            rescue HiveException => e
                puts e.message
            end
        end

        def queen; self.each{|bug| return bug if bug.class.name == 'Hive::Queen'}; end
    end

    # Extend Ruby's native RuntimeError class and call it our own HiveException. This allowed me to do a few things like suppress warnings about non-existent methods in the Bug::self.announce method in bug.rb.
    class HiveException < RuntimeError
        ErrorCodes = {:InvalidPlacement => 1}
        SuppressMissingMethods = ['move','to_ary','bug','[]','sides','+','top_left','top_center','top_right','bottom_right','bottom_center','bottom_left']
    end
end

# These two classes are also helper classes like the HiveException class that make errors look a little bit nicer if they happen.
class NilClass
    def method_missing(meth, *args, &block)
        raise Hive::HiveException, "Something bad happened in " << caller[0] << " (missing method " << meth.to_s << ")" if Hive::HiveException::SuppressMissingMethods.include?(meth.to_s) == false
    end
end

class FalseClass
    def method_missing(meth, *args, &block)
        raise Hive::HiveException, "Something bad happened in " << caller[0] << " (missing method " << meth.to_s << ")" if Hive::HiveException::SuppressMissingMethods.include?(meth.to_s) == false
    end
end

# Include the bug.rb, surface.rb, and side.rb files
require_relative 'bug'
require_relative 'surface'
require_relative 'side'

# $game will become the global variable that we can use to talk amongst each of our classes and objects. It is persistent, because it starts with a $, so that means that wherever we are in the program we can always use $game, unlike most other variables. 
$game = Hive::Game.new
$game.play