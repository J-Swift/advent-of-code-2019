#!/usr/bin/env ruby

FILENAME='input.txt'
DEBUG=ENV.fetch('DEBUG', false)
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

class LogoWrapper
    def initialize
        @current_direction = :up
        @current_space = [0, 0]
        @painted_spaces = {"0,0" => :white}
    end

    def print_result!
        comps = @painted_spaces.select { |k, v| v == :white }.keys.map { |it| it.split(',').map(&:to_i) }
        min_x = comps.map(&:first).min
        max_x = comps.map(&:first).max
        min_y = comps.map(&:last).min
        max_y = comps.map(&:last).max

        x_adjust = -min_x
        y_adjust = -min_y

        res = []

        comps.each do |x,y|
            row = res[y+y_adjust] || []
            row[x+x_adjust] = "X"
            res[y+y_adjust] = row
        end

        res.reverse.each do |row|
            puts row.map { |it| it || " " }.join('')
        end
    end

    def get_current_color
        key = @current_space.join(',')
        @painted_spaces[key] || :black
    end

    def paint_black!
        key = @current_space.join(',')
        @painted_spaces[key] = :black
    end

    def paint_white!
        key = @current_space.join(',')
        @painted_spaces[key] = :white
    end

    def turn_left!
        @current_direction = case @current_direction
        when :up
            :left
        when :left
            :down
        when :down
            :right
        when :right
            :up
        end

        move!
    end
    
    def turn_right!
        @current_direction = case @current_direction
        when :up
            :right
        when :left
            :up
        when :down
            :left
        when :right
            :down
        end

        move!
    end

    private

    def move!
        offset = case @current_direction
        when :up
            [0, 1]
        when :left
            [-1, 0]
        when :down
            [0, -1]
        when :right
            [1, 0]
        end

        @current_space = [@current_space, offset].transpose.map { |it| it.reduce(&:+) }
    end
end

class LogoInputSource
    def initialize(logo_wrapper)
        @logo_wrapper = logo_wrapper
    end

    def get_input
        color = @logo_wrapper.get_current_color
        case color
        when :black
            0
        when :white
            1
        end
    end
end

class LogoOutputSource
    def initialize(logo_wrapper)
        @logo_wrapper = logo_wrapper
        @awaiting_color = true
    end

    def send_output(output)
        if @awaiting_color
            handle_color(output)
        else
            handle_turn(output)
        end

        @awaiting_color = !@awaiting_color
    end

    def handle_color(output)
        case output
        when 0
            @logo_wrapper.paint_black!
        when 1
            @logo_wrapper.paint_white!
        else
            raise "Invalid output [#{output}]"
        end
    end

    def handle_turn(output)
        case output
        when 0
            @logo_wrapper.turn_left!
        when 1
            @logo_wrapper.turn_right!
        else
            raise "Invalid output [#{output}]"
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

def read_inputs
    File.readlines(FILENAME).map(&:strip)[0].split(",").map(&:to_i)
end

def main
    program = read_inputs

    logo_wrapper = LogoWrapper.new
    icp = IntCodeProgram.new(MemorySpace.new(program), LogoInputSource.new(logo_wrapper), LogoOutputSource.new(logo_wrapper))
    icp.run!

    logo_wrapper.print_result!
end

main
