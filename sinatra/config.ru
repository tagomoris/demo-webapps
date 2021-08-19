# frozen_string_literal: true
require_relative "./app"

require "sinatra/base"
require "rack/protection/base" # it's in the sinatra repository
require "right_speed"

sinatra_hook = ->(){
  Sinatra::Base.singleton_methods.select{|name| name.to_s.end_with?("=")}.each do |setter_name|
    # Target methods are only simple getter methods paired with setter
    getter = setter_name.to_s.chop.to_s
    boolean = "#{getter}?".intern
    if Sinatra::Base.respond_to?(boolean)
      RightSpeed::RactorHelper.overwrite_method(Sinatra::Base.singleton_class, boolean, Sinatra::Base.send(boolean)) # be prior to getter because it calls the getter
    end
    if Sinatra::Base.respond_to?(getter)
      RightSpeed::RactorHelper.overwrite_method(Sinatra::Base.singleton_class, getter, Sinatra::Base.send(getter))
    end
  end
  RightSpeed::RactorHelper.overwrite_method(Sinatra::Base.singleton_class, :routes, Sinatra::Base.routes)
  RightSpeed::RactorHelper.overwrite_method(Sinatra::Base.singleton_class, :filters, Sinatra::Base.filters)
  RightSpeed::RactorHelper.overwrite_method(Sinatra::Base.singleton_class, :templates, Sinatra::Base.templates)
  RightSpeed::RactorHelper.overwrite_method(Sinatra::Base.singleton_class, :extensions, Sinatra::Base.extensions)
  RightSpeed::RactorHelper.overwrite_method(Sinatra::Base.singleton_class, :middleware, Sinatra::Base.middleware)
  errors = Sinatra::Base.errors
  errors.keys.each do |key|
    key.freeze
    errors[key] = Ractor.make_shareable(errors[key])
  end
  RightSpeed::RactorHelper.overwrite_method(Sinatra::Base.singleton_class, :errors, errors)
  Rack::Protection::Base::DEFAULT_OPTIONS.values.each{|v| v.freeze }
  Rack::Protection::Base::DEFAULT_OPTIONS.freeze
  RightSpeed::RactorHelper.overwrite_method(Sinatra::Base.singleton_class, :setup_protection) do |_|
    # Disable Rack::Protection always, for now, because of Hash/String dynamically created in the method
  end
  RightSpeed::RactorHelper.overwrite_method(Sinatra::Base.singleton_class, :prototype) do
    Ractor.current['sinatra_prototype'] ||= Sinatra::Base.new
  end
}

# <internal:ractor>:816:in `make_shareable': can not make shareable Proc because it can refer unshareable object #<UnboundMethod: Sinatra::Base#ERROR (?-mix:.*)() /Users/tagomoris/.rbenv/versions/3.1.0-dev/lib/ruby/gems/3.1.0/gems/sinatra-2.1.0/lib/sinatra/base.rb:1872> from variable `unbound_method' (Ractor::IsolationError)
# 	from /Users/tagomoris/gh/demo-webapps/sinatra/config.ru:27:in `block (3 levels) in <main>'
# 	from /Users/tagomoris/gh/demo-webapps/sinatra/config.ru:25:in `each'
# 	from /Users/tagomoris/gh/demo-webapps/sinatra/config.ru:25:in `block (2 levels) in <main>'
# 	from /Users/tagomoris/.rbenv/versions/3.1.0-dev/lib/ruby/gems/3.1.0/gems/right_speed-0.1.0/lib/right_speed/server.rb:54:in `block in run'
# 	from /Users/tagomoris/.rbenv/versions/3.1.0-dev/lib/ruby/gems/3.1.0/gems/right_speed-0.1.0/lib/right_speed/server.rb:52:in `each'
# 	from /Users/tagomoris/.rbenv/versions/3.1.0-dev/lib/ruby/gems/3.1.0/gems/right_speed-0.1.0/lib/right_speed/server.rb:52:in `run'
# 	from /Users/tagomoris/.rbenv/versions/3.1.0-dev/lib/ruby/gems/3.1.0/gems/right_speed-0.1.0/lib/rack/handler/right_speed.rb:19:in `run'
# 	from /Users/tagomoris/.rbenv/versions/3.1.0-dev/lib/ruby/gems/3.1.0/gems/rack-2.2.3/lib/rack/server.rb:327:in `start'
# 	from /Users/tagomoris/.rbenv/versions/3.1.0-dev/lib/ruby/gems/3.1.0/gems/rack-2.2.3/lib/rack/server.rb:168:in `start'
# 	from /Users/tagomoris/.rbenv/versions/3.1.0-dev/lib/ruby/gems/3.1.0/gems/rack-2.2.3/bin/rackup:5:in `<top (required)>'
# 	from /Users/tagomoris/.rbenv/versions/3.1.0-dev/bin/rackup:23:in `load'
# 	from /Users/tagomoris/.rbenv/versions/3.1.0-dev/bin/rackup:23:in `<main>'

Ractor.current[RightSpeed::CONFIG_HOOK_KEY] ||= []
Ractor.current[RightSpeed::CONFIG_HOOK_KEY] << sinatra_hook

run DemoApp
