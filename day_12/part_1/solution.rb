#!/usr/bin/env ruby

FILENAME='input.txt'

Coords = Struct.new(:x, :y, :z)

class Moon
    attr_accessor :position, :velocity

    def initialize(x, y, z)
        @position = Coords.new(x, y, z)
        @velocity = Coords.new(0, 0, 0)
    end

    def total_energy
        potential_energy * kinetic_energy
    end

    def apply_gravity!(compared_to)
        velocity.x += -(position.x <=> compared_to.position.x)
        velocity.y += -(position.y <=> compared_to.position.y)
        velocity.z += -(position.z <=> compared_to.position.z)
    end

    def apply_velocity!
        position.x += velocity.x
        position.y += velocity.y
        position.z += velocity.z
    end

    private

    def potential_energy
        sum_absolutes(position)
    end

    def kinetic_energy
        sum_absolutes(velocity)
    end

    def sum_absolutes(coord)
        coord.x.abs + coord.y.abs + coord.z.abs
    end
end

def tick!(moons)
    moons.combination(2).to_a.each do |from, to|
        from.apply_gravity!(to)
        to.apply_gravity!(from)
    end
    moons.each(&:apply_velocity!)
end

def parse_moon(str)
    x = str.match(/x=(-?\d+)/)[1].to_i
    y = str.match(/y=(-?\d+)/)[1].to_i
    z = str.match(/z=(-?\d+)/)[1].to_i
    Moon.new(x, y, z)
end

def read_inputs
    File.readlines(FILENAME).map(&:strip).map { |it| parse_moon(it) }
end

def main
    moons = read_inputs
    1000.times { tick!(moons) }
    puts moons.map(&:total_energy).reduce(&:+)
end

main
