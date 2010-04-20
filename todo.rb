#!/usr/bin/env ruby1.9
require 'rubygems'
require 'chronic'
require 'dm-core'
require 'dm-timestamps'

## Database stuff
DataMapper.setup :default, "sqlite3://#{Dir.pwd}/db.sqlite3"
class TodoItem
    include DataMapper::Resource
    property :id, Serial
    property :title, String
    property :created_at, DateTime
    property :due_at, DateTime
    property :completed_at, DateTime
    property :completed, Boolean, :default=>false
    property :important, Boolean, :default=>false

    def display to
        to.printf "[%s] %4d: %s\n", completed ? 'x':' ', id, title
    end
end
DataMapper.auto_upgrade!


## Interface stuff
class Todo
    def initialize(output, input)
        @out = output
        @in = input
        @running = true
        @out.puts "Todo List"
        @out.puts 'Use `help` to get list of commands'
    end

    def go
        while @running
            doLine
        end
    end

    def doLine
        @out.print ': '
        line = @in.gets
        if line
            processLine line.strip
        else
            done
        end
    end

    def processLine line
        if line == 'help'
            help
        elsif line == 'exit'
            done
        elsif line[0] == ?+
            addItem line[1..-1]
        elsif line == 'todo'
            outstanding
        elsif line[0] == ?/
            check line[1..-1].to_i
        elsif line[0] == ?@
            setDue line[1..-1]
        end
     end

    # Commands
    def help
        @out.puts "Todo Commands:"
        @out.puts "help -- Displays this help message"
        @out.puts "exit -- Quits the program"
        @out.puts "todo -- Lists outstanding items"

        @out.puts "+(title) -- Adds new todo item with specified title"
        @out.puts "/(id) -- Checks or unchecks item with specified ID"
        @out.puts "@(id) (time) -- Marks item to be due before time"
    end

    def done #exit
        @out.puts "Goodbye."
        @running = false
    end

    def addItem title #+title
        item = TodoItem.new
        item.title = title
        item.save
        @out.puts "Added item ##{item.id} (#{item.title})"
    end

    def outstanding #todo
        TodoItem.all(:completed=>false).each do |item|
            item.display @out
        end
    end

    def check id #/(id)
        unless id
            @out.puts "Bad ID"
        end

        item = TodoItem.get id
        unless item
            @out.puts "Bad ID"
        end

        item.completed = !item.completed
        item.completed_at = Time.now
        item.save
    end

    def setDue line #@(id) (time)
        id, time = line.split(' ', 2)
        id = id.to_i
        unless id or time
            @out.puts "Bad ID or no time"
        end

        item = TodoItem.get id
        unless item
            @out.puts "Bad ID"
        end

        #Look up time
        time = Chronic.parse time
        unless time
            @out.puts "Bad time"
        end

        item.due_at = time
        item.save

        @out.puts "Set due time for #{item.id} to #{item.due_at}"
    end
end


## Starting up stuff
todo = Todo.new $stdout, $stdin
todo.go