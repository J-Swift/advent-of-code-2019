#!/usr/bin/env ruby

FILENAME='input.txt'
# DEBUG=true
DEBUG=false
DONE=Object.new

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
end

class AdOp < Op
    def perform
        a, b = resolve_values(2)
        dest = program[ipointer+3]
        program[dest] = a + b
        ipointer + 4
    end
end

class MultOp < Op
    def perform
        a, b = resolve_values(2)
        dest = program[ipointer+3]
        program[dest] = a * b
        ipointer + 4
    end
end

# TODO: doesnt take a mode
class InputOp < Op
    def perform
        print "INPUT: "
        input = gets.chomp.to_i
        dest = program[ipointer+1]
        puts "   > [#{dest}] [#{input}]" if DEBUG
        program[dest] = input
        ipointer + 2 
    end
end

# TODO: doesnt take a mode
class OutputOp < Op
    def perform
        src = program[ipointer+1]
        puts "   > [#{src}]" if DEBUG
        puts "OUTPUT: #{program[src]}"
        ipointer + 2
    end
end

# TODO: doesnt take a mode
class DoneOp < Op
    def perform
        puts '> Program Complete'
        DONE
    end
end

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

def parse_opcode(value)
    strcode = value.to_s.rjust(5, "0").split('')
    [strcode[-2..].join.to_i, strcode[0...-2].map(&:to_i)]
end

def handle_opcode(idx, program)
    opcode, modes = parse_opcode(program[idx])
    puts "handling [#{opcode}] modes [#{modes}]" if DEBUG
    case opcode
    when 1 # add
        op = AdOp.new(idx, program, modes)
        return op.perform
    when 2 # multiply
        op = MultOp.new(idx, program, modes)
        return op.perform
    when 3 # take user input
        op = InputOp.new(idx, program, modes)
        return op.perform
    when 4 # print to output
        op = OutputOp.new(idx, program, modes)
        return op.perform
    when 99 # exit
        op = DoneOp.new(idx, program, modes)
        return op.perform
    else
        raise "Invalid opcode [#{opcode}]"
    end
end

def read_inputs
    File.readlines(FILENAME).map(&:strip)[0].split(",").map(&:to_i)
end

def main
    program = read_inputs
    instruction_pointer = 0

    while instruction_pointer != DONE
        instruction_pointer = handle_opcode(instruction_pointer, program)
        puts "   > #{program.inspect}" if DEBUG
    end
end

main
