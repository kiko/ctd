module User
  class << self
    def name
      `git config --get user.name`.chomp
    end

    def email
      `git config --get user.email`.chomp
    end
  end
end
