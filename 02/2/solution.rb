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
    orig_program = read_inputs
    pointer = 0

    for noun in 0..99 do
        break if !$keep_going

        for verb in 0..99 do
            break if !$keep_going

            pointer = 0
            program = orig_program.dup
            program[1] = noun
            program[2] = verb

            while $keep_going
                handle_opcode(pointer, program)
                pointer += 4
            end

            if program[0] != 19690720
                $keep_going = true
            else
                els = program[1..2]
                puts els.inspect
                puts 100 * els[0] + els[1]
            end
        end
    end
end

main
