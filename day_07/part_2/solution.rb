#!/usr/bin/env ruby

FILENAME='input.txt'
DEBUG=ENV.fetch('DEBUG', false)
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
    def initialize(program, input_source, output_source, instruction_pointer = 0)
        @program = program
        @instruction_pointer = instruction_pointer
        @input_source = input_source
        @output_source = output_source
    end

    def run!
        puts "RUNNING" if DEBUG
        puts '--------------------' if DEBUG
        puts @program.inspect if DEBUG

        while @instruction_pointer != DONE
            @instruction_pointer = handle_opcode(@instruction_pointer, @program)
            puts '--------------------' if DEBUG
            puts @program.inspect if DEBUG
        end
    end

    private

    def parse_opcode(value)
        strcode = value.to_s.rjust(5, "0").split('')
        [strcode[-2..].join.to_i, strcode[0...-2].map(&:to_i)]
    end

    def handle_opcode(idx, program)
        opcode, modes = parse_opcode(program[idx])
        puts "   > [ip #{idx}] parsed [#{program[idx]}] [op #{opcode}] modes [#{modes.join(',')}]" if DEBUG
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

class ThrusterOutputSource
    attr_reader :last_output

    def send_output(output)
        @last_output = output
    end
end

class BufferedIntCodeProgram
    attr_accessor :input_source, :output_source

    def initialize(program)
        @program = program
        @instruction_pointer = 0
    end

    def run!
        Thread.new do
            icp = IntCodeProgram.new(@program, self.input_source, self.output_source, @instruction_pointer)
            icp.run!
            icp
        end
    end
end

def run_permutation(permutation, program)
    initial_signals = permutation.map do |i|
        [i]
    end
    initial_signals[0] << 0
    icps = initial_signals.each_with_index.map do |signals, idx|
        icp = BufferedIntCodeProgram.new(program.dup)
        icp.input_source = Input::BufferedInputSource.new(signals, -> { sleep 0.001 } )
        icp
    end
    icps.each_with_index do |icp, idx|
        next_icp = icps[(idx+1) % icps.size]
        icp.output_source = Output::BufferedOutputSource.new(next_icp.input_source.buffer)
    end

    thruster_out = ThrusterOutputSource.new
    icps.last.output_source = Output::FanoutOutputSource.new([thruster_out, icps.last.output_source])

    programs = icps.map do |icp|
        icp.run!
    end
    programs.each(&:join)
    thruster_out.last_output
end

def main
    program = read_inputs

    max = [5,6,7,8,9].permutation.max_by do |permutation|
        run_permutation(permutation, program)
    end
    puts run_permutation(max, program)
end

main
