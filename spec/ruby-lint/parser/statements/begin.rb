require File.expand_path('../../../../helper', __FILE__)

describe 'Parsing begin/rescue statements' do
  should 'parse a multi line statement' do
    code = <<-CODE
begin
  rescue_body
rescue Foo
  foo_body
rescue Bar, Baz => e
  bar_baz_body
else
  else_body
ensure
  ensure_body
end
    CODE

    parse(code).should == s(
      :begin,
      s(
        :body,
        [s(:method, 'rescue_body')],
        [
          s(:rescue, nil, [s(:constant, 'Foo')], nil, [s(:method, 'foo_body')]),
          s(
            :rescue,
            nil,
            [s(:constant, 'Bar'), s(:constant, 'Baz')],
            s(:local_variable, 'e'),
            [s(:method, 'bar_baz_body')]
          )
        ],
        s(:else, s(:method, 'else_body')),
        s(:ensure, s(:method, 'ensure_body'))
      )
    )
  end

  should 'parse a single line statement' do
    parse('foo rescue bar').should == s(
      :rescue,
      s(:method, 'foo'),
      nil,
      nil,
      s(:method, 'bar')
    )
  end
end