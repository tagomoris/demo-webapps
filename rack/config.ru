# frozen_string_literal: true
class DemoApp
  def call(env)
    [200, {'Content-Type' => 'text/plain', 'Content-Length' => 2.to_s}, ['OK']]
  end
end

run DemoApp.new
