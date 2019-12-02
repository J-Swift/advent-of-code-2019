#!/usr/bin/env ruby

FILENAME='input.txt'
DEBUG=false

def handle_opcode(idx, program)
    opcode = program[idx]
    puts "handling [#{opcode}]" if DEBUG
    case opcode
    when 1
        a, b, dest = program[idx+1..idx+3]
        puts "   > [#{a}] [#{b}] [#{dest}]" if DEBUG
        program[dest] = program[a] + program[b]
        puts "   > #{program.inspect}" if DEBUG
    when 2
        a, b, dest = program[idx+1..idx+3]
        puts "   > [#{a}] [#{b}] [#{dest}]" if DEBUG
        program[dest] = program[a] * program[b]
        puts "   > #{program.inspect}" if DEBUG
    when 99
        $keep_going = false
    else
        puts "Invalid opcode [#{opcode}]" if DEBUG
        $keep_going = false
    end
end

def read_inputs
    File.readlines(FILENAME).map(&:strip)[0].split(",").map(&:to_i)
end

$keep_going = true

def main
    program = read_inputs
    pointer = 0

    program[1] = 12
    program[2] = 2

    while $keep_going
        handle_opcode(pointer, program)
        pointer += 4
    end

    puts program[0]
end

main
