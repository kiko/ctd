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

while line = Readline.readline('text> ', true)
  break if line.empty? or line == 'exit'

  note = Note.new(line)

  notes << note

  notes.each_with_index do |item, i|
    puts "#{i + 1}. #{item['content']}, by #{item['author']}"
  end

  open('data.json', 'wb+') { |f| f.write original.to_json }
end

