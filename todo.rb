require 'readline'
require 'optparse'
require 'json'
require 'pp'

json = <<EOF
{"todo":
  {"version":"0.0.01",
    "notes":
    [
      { "priority":"medium",
        "author":"Tadahiko Uehara",
        "time":"123123",
        "content":"write a devtodo in Ruby" }
    ]
  }
}
EOF

#p json = File.read('data.json')

original = JSON.parse(json)
notes = original['todo']['notes']

p notes
options = {}

$0 = "#{__FILE__} #{ARGV.join(' ')}"
op = OptionParser.new{|o|
  o.on('-a', '--add', 'add new item'){ options[:add] = true }
  o.on('-h', '--help', 'help'){ puts o }
}

op.parse!(ARGV)

p options


while line = Readline.readline('text> ', true)
  break if line.empty? or line == 'exit'

  note = {
    content: line,
    author:  'Tadahiko Uehara',
    time: Time.now.to_i,
    childs: []
  }
  notes << note

  notes.each_with_index do |item, i|
    puts "#{i + 1}. #{item['content']}, by #{item['author']}"
  end

  open('data.json', 'wb+') { |f| f.write original.to_json }

  #p json = File.read('data.json')
end

