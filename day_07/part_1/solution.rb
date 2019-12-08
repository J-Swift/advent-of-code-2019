#!/usr/bin/env ruby

FILENAME='input.txt'
# DEBUG=true
DEBUG=false
DONE=Object.new.freeze

class Op
    attr_reader :ipointer, :modes, :program

    def initialize(ipointer, program, modes)
        @ipointer, @program, @modes = ipointer, program, modes
    end

    def resolve_values(num)
        (1..num).reduce([]) do |memo, n|
            raw_val = program[ipointer+n]
            resolved_val = value_for_mode(modes.pop, program, raw_val)
            memo << resolved_val
        end
    end

    private

    def value_for_mode(mode, program, value)
        case mode
        when 0 # position
            program[value]
        when 1 # immediate
            value
        else
            raise "Invalid mode [#{mode}]"
        end
    end
end

class AdOp < Op
    def perform
        a, b = resolve_values(2)
        dest = program[ipointer+3]
        puts "   > add [#{a}] [#{b}] [#{dest}]" if DEBUG
        program[dest] = a + b
        ipointer + 4
    end
end

class MultOp < Op
    def perform
        a, b = resolve_values(2)
        dest = program[ipointer+3]
        puts "   > mult [#{a}] [#{b}] [#{dest}]" if DEBUG
        program[dest] = a * b
        ipointer + 4
    end
end

class JumpIfTrueOp < Op
    def perform
        a, dest = resolve_values(2)
        puts "   > JT [#{a}] [#{dest}]" if DEBUG
        a != 0 ? dest : ipointer + 3
    end
end

class JumpIfFalseOp < Op
    def perform
        a, dest = resolve_values(2)
        puts "   > JF [#{a}] [#{dest}]" if DEBUG
        a == 0 ? dest : ipointer + 3
    end
end

class IsLessThanOp < Op
    def perform
        a, b = resolve_values(2)
        dest = program[ipointer+3]
        puts "   > LT [#{a}] [#{b}] [#{dest}]" if DEBUG
        program[dest] = a < b ? 1 : 0
        ipointer + 4
    end
end

class IsEqualOp < Op
    def perform
        a, b = resolve_values(2)
        dest = program[ipointer+3]
        puts "   > EQ [#{a}] [#{b}] [#{dest}]" if DEBUG
        program[dest] = a == b ? 1 : 0
        ipointer + 4
    end
end

# TODO: doesnt take a mode
class InputOp < Op
    def perform(source)
        input = source.get_input
        dest = program[ipointer+1]
        puts "   > IN [#{dest}] [#{input}]" if DEBUG
        program[dest] = input
        ipointer + 2 
    end
end

class OutputOp < Op
    def perform(source)
        src, = resolve_values(1)
        puts "   > OUT [#{src}]" if DEBUG
        source.send_output(src)
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
end

class IntCodeProgram
    def initialize(program, input_source, output_source, instruction_pointer = 0)
        @program = program
        @instruction_pointer = instruction_pointer
        @input_source = input_source
        @output_source = output_source
    end

    def run!

        puts "   > RUNNING #{@program.inspect}" if DEBUG

        while @instruction_pointer != DONE
            @instruction_pointer = handle_opcode(@instruction_pointer, @program)
            # puts '----------------------------'
            puts "   > #{@program.inspect}" if DEBUG
        end
    end

    private

    def parse_opcode(value)
        strcode = value.to_s.rjust(5, "0").split('')
        [strcode[-2..].join.to_i, strcode[0...-2].map(&:to_i)]
    end

    def handle_opcode(idx, program)
        opcode, modes = parse_opcode(program[idx])
        puts "[ip #{idx}] parsed [#{program[idx]}] [op #{opcode}] modes [#{modes.join(',')}]" if DEBUG
        case opcode
        when 1 # add
            op = AdOp.new(idx, program, modes)
            return op.perform
        when 2 # multiply
            op = MultOp.new(idx, program, modes)
            return op.perform
        when 3 # take user input
            op = InputOp.new(idx, program, modes)
            return op.perform(@input_source)
        when 4 # print to output
            op = OutputOp.new(idx, program, modes)
            return op.perform(@output_source)
        when 5 # jump-if-true
            op = JumpIfTrueOp.new(idx, program, modes)
            return op.perform
        when 6 # jump-if-false
            op = JumpIfFalseOp.new(idx, program, modes)
            return op.perform
        when 7 # is-less-than
            op = IsLessThanOp.new(idx, program, modes)
            return op.perform
        when 8 # is-equal
            op = IsEqualOp.new(idx, program, modes)
            return op.perform
        when 99 # exit
            op = DoneOp.new(idx, program, modes)
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

    max = [0,1,2,3,4].permutation.max_by do |permutation|
        last_output = 0
        permutation.each do |i|
            on_output = ->(x) { last_output = x }

            icp = IntCodeProgram.new(program.dup, Input::StaticInputSource.new([i, last_output]), Output::CallbackOutputSource.new(on_output))
            icp.run!
        end
        last_output
    end
    puts max.inspect

    last_output = 0
    max.each do |i|
        on_output = ->(x) { last_output = x }

        icp = IntCodeProgram.new(program.dup, Input::StaticInputSource.new([i, last_output]), Output::CallbackOutputSource.new(on_output))
        icp.run!
    end
    puts last_output
end

main
