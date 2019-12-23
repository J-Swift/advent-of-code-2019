#!/usr/bin/env ruby

FILENAME='input.txt'
DEBUG=ENV.fetch('DEBUG', false)
$draw_board=ENV.fetch('DRAW_BOARD', false)
DONE=Object.new.freeze

class MemorySpace
    def initialize(initial)
        @memory = initial.dup
    end

    def [](key)
        raise 'negative idx' if key.is_a?(Integer) && key < 0
        val = @memory[key]
        if val.is_a?(Array)
            val.map { |it| it || 0 }
        else
            val || 0
        end
    end

    def []=(key, value)
        raise 'negative idx' if key.is_a?(Integer) && key < 0
        @memory[key] = value
    end

    def inspect
        if @memory.length > 100
            puts "[#{@memory[0..100].join(",")} ...]"
        else
            puts "[#{@memory.join(",")}]"
        end
    end
end

class Op
    attr_reader :ipointer, :modes, :program, :relbase

    def initialize(ipointer, relbase, program, modes)
        @ipointer, @relbase, @program, @modes = ipointer, relbase, program, modes
    end

    def resolve_values(num)
        (1..num).reduce([]) do |memo, n|
            raw_val = program[ipointer+n]
            resolved_val = value_for_mode(modes.pop, program, relbase, raw_val)
            memo << resolved_val
        end
    end

    def resolve_destination(num)
        dest = program[ipointer+num]
        case mode = modes.pop
        when 0 # position
            dest
        when 2 # relative
            dest + relbase
        else
            raise "Invalid mode [#{mode}]"
        end
    end

    private

    def value_for_mode(mode, program, relbase, value)
        case mode
        when 0 # position
            program[value]
        when 1 # immediate
            value
        when 2 # relative
            program[relbase + value]
        else
            raise "Invalid mode [#{mode}]"
        end
    end
end

class AdOp < Op
    def perform
        a, b = resolve_values(2)
        dest = resolve_destination(3)
        puts "   > #{program[ipointer..ipointer+3]}" if DEBUG
        puts "   > add [#{a}] [#{b}] [#{dest}]" if DEBUG
        program[dest] = a + b
        ipointer + 4
    end
end

class MultOp < Op
    def perform
        a, b = resolve_values(2)
        dest = resolve_destination(3)
        puts "   > #{program[ipointer..ipointer+3]}" if DEBUG
        puts "   > mult [#{a}] [#{b}] [#{dest}]" if DEBUG
        program[dest] = a * b
        ipointer + 4
    end
end

class JumpIfTrueOp < Op
    def perform
        a, dest = resolve_values(2)
        puts "   > #{program[ipointer..ipointer+2]}" if DEBUG
        puts "   > JT [#{a}] [#{dest}]" if DEBUG
        a != 0 ? dest : ipointer + 3
    end
end

class JumpIfFalseOp < Op
    def perform
        a, dest = resolve_values(2)
        puts "   > #{program[ipointer..ipointer+2]}" if DEBUG
        puts "   > JF [#{a}] [#{dest}]" if DEBUG
        a == 0 ? dest : ipointer + 3
    end
end

class IsLessThanOp < Op
    def perform
        a, b = resolve_values(2)
        #dest = program[ipointer+3]
        dest = resolve_destination(3)
        puts "   > #{program[ipointer..ipointer+3]}" if DEBUG
        puts "   > LT [#{a}] [#{b}] [#{dest}]" if DEBUG
        program[dest] = a < b ? 1 : 0
        ipointer + 4
    end
end

class IsEqualOp < Op
    def perform
        a, b = resolve_values(2)
        dest = resolve_destination(3)
        puts "   > #{program[ipointer..ipointer+3]}" if DEBUG
        puts "   > EQ [#{a}] [#{b}] [#{dest}]" if DEBUG
        program[dest] = a == b ? 1 : 0
        ipointer + 4
    end
end

class InputOp < Op
    def perform(source)
        input = source.get_input
        dest = resolve_destination(1)
        puts "   > #{program[ipointer..ipointer+1]}" if DEBUG
        puts "   > IN [#{dest}] [#{input}]" if DEBUG
        program[dest] = input
        ipointer + 2 
    end
end

class OutputOp < Op
    def perform(source)
        src, = resolve_values(1)
        puts "   > #{program[ipointer..ipointer+1]}" if DEBUG
        puts "   > OUT [#{src}]" if DEBUG
        source.send_output(src)
        ipointer + 2
    end
end

class AdjustRelativeBaseOp < Op
    def perform(&block)
        a, = resolve_values(1)
        puts "   > #{program[ipointer..ipointer+1]}" if DEBUG
        puts "   > ADJRELBASE from [#{@relbase}] [#{a}]" if DEBUG
        block.call(@relbase+a)
        ipointer + 2
    end
end

# TODO: doesnt take a mode
class DoneOp < Op
    def perform
        puts '> Program Complete' if DEBUG
        DONE
    end
end

module Input
    class StdInInputSource
        def get_input
            print "INPUT: "
            gets.chomp.to_i
        end
    end

    class StaticInputSource
        def initialize(inputs)
            @inputs = inputs
            @current_input = 0
        end

        def get_input
            input = @inputs[@current_input]
            @current_input += 1
            input
        end
    end

    class BufferedInputSource
        attr_reader :buffer

        def initialize(buffer, on_empty_buffer_callback)
            @buffer = buffer
            @on_empty_buffer_callback = on_empty_buffer_callback
        end

        def get_input
            while @buffer.empty?
                @on_empty_buffer_callback.call
            end
            @buffer.shift
        end
    end
end

module Output
    class StdOutOutputSource
        def send_output(output)
            puts "OUTPUT: #{output}"
        end
    end

    class CallbackOutputSource
        def initialize(on_output)
            @on_output = on_output
        end

        def send_output(output)
            @on_output.call(output)
        end
    end

    class BufferedOutputSource
        def initialize(buffer)
            @buffer = buffer
        end

        def send_output(output)
            @buffer << output
        end
    end

    class FanoutOutputSource
        def initialize(sources)
            @sources = sources
        end

        def send_output(output)
            @sources.each { |it| it.send_output(output) }
        end
    end
end

class IntCodeProgram
    def initialize(program, input_source, output_source, instruction_pointer = 0, relative_base = 0)
        @program = program
        @instruction_pointer = instruction_pointer
        @relative_base = relative_base
        @input_source = input_source
        @output_source = output_source
    end

    def run!
        puts "RUNNING" if DEBUG
        puts '--------------------' if DEBUG
        puts @program.inspect if DEBUG

        while @instruction_pointer != DONE
            @instruction_pointer = handle_opcode(@instruction_pointer, @relative_base, @program)
            puts '--------------------' if DEBUG
            puts @program.inspect if DEBUG
        end
    end

    private

    def parse_opcode(value)
        strcode = value.to_s.rjust(5, "0").split('')
        [strcode[-2..].join.to_i, strcode[0...-2].map(&:to_i)]
    end

    def handle_opcode(idx, relbase, program)
        opcode, modes = parse_opcode(program[idx])
        puts "   > [ip #{idx}] [rb #{relbase}] parsed [#{program[idx]}] [op #{opcode}] modes [#{modes.join(',')}]" if DEBUG
        case opcode
        when 1 # add
            op = AdOp.new(idx, relbase, program, modes)
            return op.perform
        when 2 # multiply
            op = MultOp.new(idx, relbase, program, modes)
            return op.perform
        when 3 # take user input
            op = InputOp.new(idx, relbase, program, modes)
            return op.perform(@input_source)
        when 4 # print to output
            op = OutputOp.new(idx, relbase, program, modes)
            return op.perform(@output_source)
        when 5 # jump-if-true
            op = JumpIfTrueOp.new(idx, relbase, program, modes)
            return op.perform
        when 6 # jump-if-false
            op = JumpIfFalseOp.new(idx, relbase, program, modes)
            return op.perform
        when 7 # is-less-than
            op = IsLessThanOp.new(idx, relbase, program, modes)
            return op.perform
        when 8 # is-equal
            op = IsEqualOp.new(idx, relbase, program, modes)
            return op.perform
        when 9 # adjust-relative-base
            op = AdjustRelativeBaseOp.new(idx, relbase, program, modes)
            return op.perform { |newbase| @relative_base = newbase }
        when 99 # exit
            op = DoneOp.new(idx, relbase, program, modes)
            return op.perform
        else
            raise "Invalid opcode [#{opcode}]"
        end
    end
end

require 'set'
class GameWrapper
    DIRECTIONS = [:east, :west, :south, :north]

    def initialize
        @gameboard = []
        @initial_space = [1000, 1000]
        @current_position = @initial_space.dup
        @oxygen_position = nil
        @best_oxygen_length = nil
        @unknowns = Set.new
        DIRECTIONS.each do |dir|
            @unknowns << current_position_offset_in_direction(dir)
        end
        set_space(@current_position, :visited)

        # @gameboard = [
        #     [nil, nil, nil],
        #     [nil, :visited, nil],
        #     [nil, :visited, nil],
        #     [nil, :visited, nil],
        #     [nil, nil, nil],
        # ]
        # @initial_space = [1, 3]
        # @current_position = [1, 1]
        # @oxygen_position = nil
        # @best_oxygen_length = nil
        # @unknowns = Set.new
        # DIRECTIONS.each do |dir|
        #     @unknowns << current_position_offset_in_direction(dir)
        # end
        # # set_space(@current_position, :visited)
        # puts pathfind_from_current([2, 3]).inspect
        # exit
    end

    def print_result!
        return unless $draw_board
        str = "\e[H\e[2J"

        @view_center ||= @initial_space.dup
        if ((@view_center[0] - @current_position[0]).abs > 25)
            @view_center[0] = @current_position[0]
        end
        if ((@view_center[1] - @current_position[1]).abs > 10)
            @view_center[1] = @current_position[1]
        end

        cols = ((@view_center[1] - 25)..(@view_center[1]+25)).map do |y|
            rows = ((@view_center[0] - 50)..(@view_center[0]+50)).map do |x|
                space = get_space([x, y])

                case
                when space == :oxygen
                    '!' 
                when [x, y] == @current_position
                    'O' 
                when [x, y] == @initial_space
                    '*' 
                when space == :visited
                    '-'
                when space == :wall
                    '#'
                when @unknowns.member?([x, y])
                    '?'
                when space == :unknown
                    ' '
                end
            end
            rows.join('')
        end
        str += cols.join("\n")
        str += "\n"
        str += @current_position.inspect
        puts str
    end

    def sending_move(direction)
        @last_direction = direction
    end

    def got_result(result)
        next_position = current_position_offset_in_direction(@last_direction)
        # puts "[#{next_position}] [#{result}]"

        case result
        when :wall
            set_space(next_position, :wall)
        when :moved
            set_space(next_position, :visited)
            DIRECTIONS.each do |dir|
                surrounding_pos = position_offset_in_direction(next_position, dir)
                if get_space(surrounding_pos) == :unknown
                    @unknowns << surrounding_pos.dup
                end
            end
            @current_position = next_position
        when :oxygen
            set_space(next_position, :oxygen)
            DIRECTIONS.each do |dir|
                surrounding_pos = position_offset_in_direction(next_position, dir)
                if get_space(surrounding_pos) == :unknown
                    @unknowns << surrounding_pos.dup
                end
            end
            @current_position = next_position

            @oxygen_position = next_position.dup
        else
            raise "Unknown result [#{result}]"
        end
    end

    def pathfind_from_current(to)
        pathfind(@current_position, to)
    end

    def pathfind(from, to)
        visited_results = {}
        to_search = [from]

        while true
            cur_pos = to_search.shift or raise 'No more points to check!'
            cur_path = visited_results[cur_pos] || []
            surrounding_pos = DIRECTIONS.map do |dir|
                resulting_path = cur_path.dup
                resulting_path << dir
                new_pos = position_offset_in_direction(cur_pos, dir)
                return resulting_path if new_pos == to
                [dir, new_pos, resulting_path]
            end
            surrounding_pos.select! { |_, pos| ![:wall, :unknown].member?(get_space(pos)) && !visited_results[pos] }
            surrounding_pos.each do |_, new_pos, resulting_path|
                visited_results[new_pos] = resulting_path
                to_search << new_pos
            end
        end
    end

    def get_random_unvisited
        if @unknowns.empty?
            puts 'EXPLORED FULLY'
            $draw_board = true
            print_result!
            calculate_oxygen!
            exit 1
        end

        res = @unknowns.to_a.sample
        @unknowns.delete(res)
        res
    end

    private

    def current_position_offset_in_direction(direction)
        position_offset_in_direction(@current_position, direction)
    end

    def position_offset_in_direction(position, direction)
        new_pos = position.dup
        case direction
        when :north
            new_pos[1] -= 1
        when :west
            new_pos[0] -= 1
        when :south
            new_pos[1] += 1
        when :east
            new_pos[0] += 1
        end
        new_pos
    end

    def set_space(space, type)
        row = @gameboard[space[1]] || []
        row[space[0]] = type
        @gameboard[space[1]] = row
    end

    def get_space(space)
        row = @gameboard[space[1]] || []
        row[space[0]] || :unknown
    end

    def calculate_oxygen!
        all_non_walls = Set.new
        @gameboard.each_with_index do |col, y|
            col ||= []
            col.each_with_index do |row, x|
                if row && row != :wall
                    all_non_walls << [x, y]
                end
            end
        end

        queue = Set.new
        visited = Set.new
        queue.add(@oxygen_position)
        visited.add(@oxygen_position)

        tick = 0
        while (all_non_walls - visited).size > 0
            next_queue = Set.new
            tick += 1
            queue.each do |cur_pos|
                potentials = DIRECTIONS.map { |dir| position_offset_in_direction(cur_pos, dir) }
                potentials.select! { |it| all_non_walls.member?(it) && !visited.member?(it) }
                potentials.each do |it|
                    next_queue.add(it)
                    visited.add(it)
                end
            end
            queue = next_queue
        end
        puts "OXYGEN SPREAD IN [#{tick}] ticks"
    end
end

class GameInputSource
    INPUTS = [:north, :south, :west, :east]
    def initialize(game_wrapper)
        @game_wrapper = game_wrapper
        @movement_path = []
        @moving_to = nil
    end

    def get_input
        if @movement_path.empty?
            @game_wrapper.print_result!
            @moving_to = @game_wrapper.get_random_unvisited
            @movement_path = @game_wrapper.pathfind_from_current(@moving_to)
        end
        # puts "move [#{@moving_to}] #{@movement_path.inspect}]"
        input = @movement_path.shift
        @game_wrapper.sending_move(input)
        INPUTS.find_index(input) + 1
    end
end

class GameOutputSource
    def initialize(game_wrapper)
        @game_wrapper = game_wrapper
    end

    TYPE_LOOKUP = {
        0 => :wall,
        1 => :moved,
        2 => :oxygen,
    }
    def send_output(output)
        @game_wrapper.got_result(TYPE_LOOKUP[output.to_i])
    end
end

def read_inputs
    File.readlines(FILENAME).map(&:strip)[0].split(",").map(&:to_i)
end

def main
    program = read_inputs

    game_wrapper = GameWrapper.new
    icp = IntCodeProgram.new(MemorySpace.new(program), GameInputSource.new(game_wrapper), GameOutputSource.new(game_wrapper))
    icp.run!
end

main
