module AdapterMock
  def with_adapter_mocked
    adapter = Minitest::Mock.new
    old_adapter = Thread.current[:innkeeper_adapter]
    Thread.current[:innkeeper_adapter] = adapter

    yield adapter
  ensure
    Thread.current[:innkeeper_adapter] = old_adapter
  end
end
