require 'spec_helper'

describe RubyLint::ConstantLoader do
  before do
    @registry    = RubyLint::Definition::Registry.new
    @definitions = ruby_object.new
    @loader      = RubyLint::ConstantLoader.new(:definitions => @definitions)

    # Having our own registry is one thing, but the definitions
    # in ruby-lint/definitions/core insist on applying themselves to the
    # global one (before we can stub it) so we borrow the result now
    @registry.stub(:registered).and_return(RubyLint.registry.registered.dup)
    @loader.stub(:registry).and_return(@registry)
  end

  context 'bootstrapping definitions' do
    before do
      @loader.bootstrap
    end

    it 'bootstraps Module' do
      @definitions.has_definition?(:const, 'Module').should == true
    end

    it 'bootstraps Fixnum' do
      @definitions.has_definition?(:const, 'Fixnum').should == true
    end

    it 'bootstraps global variables' do
      @definitions.has_definition?(:gvar, '$LOAD_PATH').should == true
    end
  end

  context 'loading constants' do
    before do
      @loader.load_constant('PP')
    end

    it 'marks bootstrapped constants as loaded' do
      @loader.bootstrap
      @loader.loaded?('Module').should == true
    end

    it 'loads a constant' do
      @loader.loaded?('PP').should == true
    end

    it 'applies a constant to a definition' do
      @definitions.has_definition?(:const, 'PP').should == true
    end

    it 'updates the registry' do
      @loader.registry.include?('PP').should == true
    end
  end

  context 'dealing with case sensitivity' do
    before do
      @loader.bootstrap
    end

    it 'does not raise when loading process.rb for the PROCESS constant' do
      block = lambda { @loader.load_constant('PROCESS') }

      block.should_not raise_error
    end
  end

  context 'iterating over an AST' do
    before do
      @ast = s(:root, s(:const, nil, 'PP'))
    end

    it 'loads a constant' do
      @loader.run([@ast])
      @loader.loaded?('PP').should == true
    end

    it 'calls the correct callbacks' do
      @loader.should_receive(:on_const)
        .with(an_instance_of(RubyLint::AST::Node))

      @loader.run([@ast])
    end
  end

  context 'iterating over an AST with PP::ObjectMixin' do
    before do
      @ast = s(:root, s(:const, s(:const, nil, 'PP'), 'ObjectMixin'))
    end

    it 'loads a constant' do
      @loader.run([@ast])
      @loader.loaded?('PP').should == true
    end

    it 'calls the correct callbacks' do
      @loader.should_receive(:on_const)
        .with(an_instance_of(RubyLint::AST::Node)).twice

      @loader.run([@ast])
    end
  end


  context 'iterating over an AST with ::PP' do
    before do
      @ast = s(:root, s(:const, s(:cbase), 'PP'))
    end

    it 'loads a constant' do
      @loader.run([@ast])
      @loader.loaded?('PP').should == true
    end

    it 'calls the correct callbacks' do
      @loader.should_receive(:on_const)
        .with(an_instance_of(RubyLint::AST::Node))

      @loader.run([@ast])
    end
  end

  context 'loading scoped constants' do
    before do
      @registry.register('Foo') do |defs|
        defs.define_constant('Foo') do |klass|
          klass.inherits(defs.constant_proxy('Object', @registry))
          klass.define_method('hello_foo')
        end
      end

      @registry.register('Foo::Bar') do |defs|
        defs.define_constant('Foo::Bar') do |klass|
          klass.inherits(defs.constant_proxy('Object', @registry))
          klass.define_method('hello_bar')
        end
      end
    end

    it 'loads a constant from a module scope' do
      code = <<-CODE
module Foo
  class Qux
    def hello_qux
      Bar.hello_bar
    end
  end
end
      CODE
      @ast = parse(code)

      @loader.run([@ast])
      @loader.loaded?('Foo::Bar').should == true
    end

    it 'loads a constant from a class scope' do
      code = <<-CODE
class Foo
  class Qux
    def hello_qux
      Bar.hello_bar
    end
  end
end
      CODE
      @ast = parse(code)

      @loader.run([@ast])
      @loader.loaded?('Foo::Bar').should == true
    end
  end
end
