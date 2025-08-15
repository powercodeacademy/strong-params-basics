# Ruby 3.3.5 compatibility fixes

# Fix for Ruby 3+ keyword argument changes
if RUBY_VERSION >= "3.0"
  # Silence warnings about keyword arguments
  Warning[:deprecated] = false
end

# Fix for potential logger issues in Ruby 3.3.5
begin
  require 'logger'
rescue LoadError
  # Logger is usually available, but this handles edge cases
end
