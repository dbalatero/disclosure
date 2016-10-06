module ShutUpBacktrace
  def self.backtrace_suppressor(&block)
    yield
  end
end
