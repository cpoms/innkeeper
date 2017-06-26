module AdapterMock
  def with_adapter_mocked
    adapter = Minitest::Mock.new
    old_adapter = Thread.current[:apartment_adapter]
    Thread.current[:apartment_adapter] = adapter

    yield adapter
  ensure
    Thread.current[:apartment_adapter] = old_adapter
  end
end
