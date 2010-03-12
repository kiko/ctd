require 'ctd/user'

class Note < Struct.new(:content, :author, :time, :childs, :done, :priority)
  include User

  def initialize(content, author = nil, time = Time.now.to_i,
                 childs = [], done = nil, priority = nil)
    self.content  = content
    self.author   = author || User.name
    self.time     = time
    self.childs   = childs
    self.done     = done
    self.priority = priority

    unless childs.empty?
      self.childs.map! do |note|
        self.class.new(note['content'],
                       note['author'],
                       note['time'],
                       note['childs'],
                       note['done'],
                       note['priority'],
                       )
      end
    end
  end

  def archive
    self.done = Time.now.to_i
  end

  def update(data)
    self.content  = data[:content]
    self.time     = data[:time]
    self.priority = data[:priority]
  end

  def to_json
    { content:  content,
      author:   author,
      time:     time,
      childs:   childs,
      done:     done,
      priority: priority,
    }.to_json
  end
end

