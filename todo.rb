#! /usr/bin/env ruby
require 'readline'
require 'optparse'
require 'json'
require 'pp'

json = File.read('data.json')

original = JSON.parse(json)
notes = original['todo']['notes']

options = {}

$0 = "#{__FILE__} #{ARGV.join(' ')}"
op = OptionParser.new{|o|
  o.on('-a', '--add', 'add new item'){ options[:add] = true }
  o.on('-h', '--help', 'help'){ puts o }
}

op.parse!(ARGV)

class Note < Struct.new(:content, :author, :time, :childs)
  def initialize(content)
    self.content = content
    self.author  = 'Tadahiko Uehara'
    self.time    = Time.now.to_i
    self.childs  = []
  end

  def to_json
    { content: content,
      author:  author,
      time:    time,
      childs:  childs,
    }.to_json
  end
end

class Notes
  attr_reader :notes, :original
  def initialize(file = nil)
    json = File.read(file || 'data.json')

    @original = JSON.parse(json) || default
    @notes = @original['todo']['notes']
    # @notes = []
    # @original['todo']['notes'].each do |note|
    #
    #   @notes << Note.new(note['content'],
    #            note['author'],
    #            note['time'],
    #                       note['childs'],
    #           )
    #end
  end

  def add(note)
    @notes << note
  end

  def remove(id)
    @notes.delete_at(id)
    exit
  end

  def list
    @notes.each_with_index do |note, i|
      puts "#{i + 1}. #{note['content']}, by #{note['author']}"
    end
  end

  def template
    {"todo"=>
      {"version" => "0.0.01",
       "notes"   => []}
    }.to_json
  end
end

notes = Notes.new

options = {}

$0 = "#{__FILE__} #{ARGV.join(' ')}"
op = OptionParser.new{|o|
  o.on('-a', '--add', 'add new item'){ options[:add] = true }
  o.on('-d', '--remove ID', Integer, 'remove an item'){|d| options[:remove] = d}
  o.on('-h', '--help', 'help'){ puts o; exit }
}

op.parse!(ARGV)

if id = options[:remove]
  notes.remove(id)
  exit
end

if options[:add]
  while line = Readline.readline('text> ', true)
    break if line.empty? or line == 'exit'

    note = Note.new(line)
    notes.add(note)

    open('data.json', 'wb+') { |f| f.write notes.original.to_json }

    notes.list
    puts "Added. To finish type 'exit' or press enter key"
  end
end

notes.list
