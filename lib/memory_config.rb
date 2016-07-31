require 'thread'

class MemoryConfig
  def initialize
    @mutex = Mutex.new
    @configs = { latency: [], status: [] }
  end

  def set(key, path, value)
    @mutex.synchronize do
      @configs[key].delete_if { |item| item[:path] == path }
      @configs[key].unshift({ path: path, value: value })
    end
  end

  def del(key, path)
    @mutex.synchronize do
      @configs[key].delete_if { |item| item[:path] == path }
    end
  end

  def get(key)
    @mutex.synchronize do
      @configs[key].dup
    end
  end
end
