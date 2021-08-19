# frozen_string_literal: true
require "sinatra/base"

class DemoApp < Sinatra::Base
  get "/" do
    "OK"
  end
  # get("/", &Ractor.make_shareable(->(){ "OK" }))
end
