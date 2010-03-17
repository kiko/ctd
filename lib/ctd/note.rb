require 'ctd/user'

class Note < Struct.new(:original, :content, :author, :time, :childs, :done, :priority)
  include User

  def initialize(original)
    self.class.members.each do |member|
      value = original[member.to_s] || original[member]

      case member
      when :original
        self.original = original
        next
      when :author
        value ||= User.name
      when :time
        value ||= Time.now.to_i
      when :childs
        value ||= []
        value.map!{|child| self.class.new(child) }
      end

      self[member] = value
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

