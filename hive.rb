#!/usr/bin/env ruby
module Hive
    Colors = {:white => 0, :black => 1}

    class Game
        attr_accessor :trays,
                      :bugs,
                      :surface,
                      :turn,
                      :turn_number

        def initialize
            puts "\nWelcome to Hive!\n****************\n"

            @turn_number = 1
            @surface = Surface.new
            @trays = [Hive::Colors[:white], Hive::Colors[:black]].collect {|tray| tray = Tray.new}
            @bugs =  [Hive::Colors[:white], Hive::Colors[:black]].collect {|tray| tray = Tray.new}
            @turn = Hive::Colors[:black]

            2.times {
                3.times { @trays[@turn] << Hive.const_get('Ant').new(@turn, @trays[turn].count) }
                3.times { @trays[@turn] << Hive.const_get('Grasshopper').new(@turn, @trays[turn].count) }
                2.times { @trays[@turn] << Hive.const_get('Spider').new(@turn, @trays[turn].count) }
                2.times { @trays[@turn] << Hive.const_get('Beetle').new(@turn, @trays[turn].count) }
                1.times { @trays[@turn] << Hive.const_get('Ladybug').new(@turn, @trays[turn].count) }
                1.times { @trays[@turn] << Hive.const_get('Mosquito').new(@turn, @trays[turn].count) }
                1.times { @trays[@turn] << Hive.const_get('Queen').new(@turn, @trays[turn].count) }
                @turn = Hive::Colors[:white]
            }
        end

        def white; return self.trays[Hive::Colors[:white]]; end
        def black; return self.trays[Hive::Colors[:black]]; end
        def turn?; return @turn == 0 ? 'White' : 'Black'; end

        def not_my_turn?(color)
            begin
                if self.turn == color
                    return false
                else
                    raise HiveException, "#{color == Hive::Colors[:white] ? "White" : "Black"}, it's not your turn!", caller
                end
            rescue HiveException => e
                puts e.message
            end
            return true
        end

        def next_turn
            $game.check_state
            $game.turn = ($game.turn == Hive::Colors[:white] ? Hive::Colors[:black] : Hive::Colors[:white])
            $game.turn_number = $game.turn_number + 1
        end

        def list_moves
            $game.surface.move_candidates($game.turn)
            puts "These are your open spots to place a new bug:\n"
            $game.surface.place_candidates($game.turn).each{|place|puts place.inspect}
        end

        def check_state
            [Hive::Colors[:white],Hive::Colors[:black]].collect{|color|
                abort("#{$game.turn?} won!") if self.trays[color].queen.is_surrounded?
            }
        end

        def play
            $game.surface.+$game.white.get('Ant')
            $game.surface.+$game.black.get('Beetle')
            $game.surface.+($game.white.get('Ant'), $game.surface.bug(Hive::Colors[:white], Bug::Types[:ant1]), Side::Faces[:bottom_left])
            #$game.surface.+($game.black.get('Grasshopper'), $game.surface.bug(Hive::Colors[:black], Bug::Types[:beetle1]), Side::Faces[:bottom_left])
            $game.surface.+($game.black.get('Grasshopper'), $game.surface.bug(Hive::Colors[:black], Bug::Types[:beetle1]), Side::Faces[:top_right])
            $game.surface.+($game.white.get('Ant'), $game.surface.bug(Hive::Colors[:white], Bug::Types[:ant2]), Side::Faces[:bottom_right])
            $game.surface.+($game.black.get('Queen'), $game.surface.bug(Hive::Colors[:black], Bug::Types[:grasshopper1]), Side::Faces[:top_right])
            $game.surface.+($game.white.get('Queen'), $game.surface.bug(Hive::Colors[:white], Bug::Types[:ant3]), Side::Faces[:bottom_right])
            $game.surface.+($game.black.get('Grasshopper'), $game.surface.bug(Hive::Colors[:black], Bug::Types[:queen1]), Side::Faces[:top_right])
            $game.surface.+($game.white.get('Spider'), $game.surface.bug(Hive::Colors[:white], Bug::Types[:queen1]), Side::Faces[:bottom_center])
            
            #$game.surface.bugs_not_in_play?
            $game.surface.bug(Hive::Colors[:black], Bug::Types[:grasshopper2]).move(Hive::Colors[:black], Bug::Types[:beetle1], Side::Faces[:bottom_left])
            
            puts "\n\n"
            puts $game.surface.bug(Hive::Colors[:white], Bug::Types[:ant2]).move_candidates            
            #$game.list_moves
        end
    end

    class Tray < Array
        
        #def flatten; return super(flatten); end
        #def to_ary; return super(to_ary); end

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

    class HiveException < RuntimeError
        ErrorCodes = {:InvalidPlacement => 1}
        SuppressMissingMethods = ['to_ary','bug','[]','sides','+','top_left','top_center','top_right','bottom_right','bottom_center','bottom_left']
    end
end

class NilClass
    def method_missing(meth, *args, &block)
        raise Hive::HiveException, "Something bad happened (missing method " << meth.to_s << ")" if Hive::HiveException::SuppressMissingMethods.include?(meth.to_s) == false
    end
end

class FalseClass
    def method_missing(meth, *args, &block)
        raise Hive::HiveException, "Something bad happened (missing method " << meth.to_s << ")" if Hive::HiveException::SuppressMissingMethods.include?(meth.to_s) == false
    end
end

require_relative 'bug'
require_relative 'surface'
require_relative 'side'

$game = Hive::Game.new
$game.play