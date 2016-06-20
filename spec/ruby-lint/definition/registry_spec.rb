require 'spec_helper'

describe RubyLint::Definition::Registry do
  before do
    @registry = RubyLint::Definition::Registry.new
  end

  context 'registering definitions' do
    it 'does not register definitions by default' do
      @registry.registered.empty?.should == true
    end

    it 'registers a definition' do
      @registry.register('String') { }

      @registry.registered.key?('String').should == true
    end
  end

  context 'checking if definitions exist' do
    it 'checks for a non existing definition' do
      @registry.include?('Foo').should == false
    end

    it 'checks for an existing definition' do
      @registry.register('Foo') { }

      @registry.include?('Foo').should == true
    end
  end

  context 'retrieving definitions' do
    it 'raises when the constant does not exist' do
      lambda { @registry.get('Foo') }.should raise_error(ArgumentError)
    end

    it 'returns the definition when it exists' do
      @registry.register('Foo') { }

      @registry.get('Foo').is_a?(Proc).should == true
    end
  end

  context 'applying definitions' do
    before do
      @root = ruby_object.new

      @registry.register('Foo') do |defs|
        defs.define_constant('Foo') do |foo|
          foo.define_method('bar')
        end
      end

      @registry.apply('Foo', @root)
    end

    it 'defines the constant' do
      @root.has_definition?(:const, 'Foo').should == true
    end

    it 'defines sub definitions correctly' do
      @root.lookup(:const, 'Foo')
        .has_definition?(:method, 'bar')
        .should == true
    end

    it 'does not overwrite existing definitions' do
      foo = @root.lookup(:const, 'Foo')

      @registry.apply('Foo', @root)

      @root.lookup(:const, 'Foo').should == foo
    end
  end

  context 'merging definitions' do
    def register_outer(registry)
      registry.register('Project') do |defs|
        defs.define_constant('Project') do |klass|
          klass.inherits(defs.constant_proxy('Object', registry))
          klass.define_method('hello')
        end
      end
    end

    def register_inner(registry)
      registry.register('Project::UI') do |defs|
        defs.define_constant('Project::UI') do |klass|
          klass.inherits(defs.constant_proxy('Object', registry))
          klass.define_method('widget_exists') do |method|
            method.define_rest_argument('args')
          end
        end
      end
    end

    def register_nested(registry)
      registry.register('Project') do |defs|
        defs.define_constant('Project') do |klass|
          klass.inherits(defs.constant_proxy('Object', RubyLint.registry))
        end
        defs.define_constant('Project::UI') do |klass|
          klass.inherits(defs.constant_proxy('Object', registry))
          klass.define_method('widget_exists') do |method|
            method.define_rest_argument('args')
          end
        end
      end
    end

    def check_merged
      @root.lookup(:const, 'Project')
        .has_definition?(:method, 'hello')
        .should == true
      @root.lookup(:const, 'Project')
        .lookup(:const, 'UI')
        .has_definition?(:method, 'widget_exists')
        .should == true
    end

    before do
      @root = ruby_object.new
    end

    it 'merges the definitions when the outer namespace is applied first' do
      register_outer(@registry)
      register_inner(@registry)
      @registry.apply('Project', @root)
      @registry.apply('Project::UI', @root)

      check_merged
    end

    it 'merges the definitions when the inner namespace is applied first' do
      register_inner(@registry)
      register_outer(@registry)
      @registry.apply('Project::UI', @root)
      @registry.apply('Project', @root)

      check_merged
    end

    it 'merges the definitions when the nested namespace is applied first' do
      register_nested(@registry)
      register_outer(@registry)
      @registry.apply('Project', @root)
      @registry.apply('Project', @root)

      check_merged
    end
  end

  context 'managing load paths' do
    before do
      @registry = RubyLint::Definition::Registry.new
    end

    it 'uses the default load path' do
      @registry.load_path
        .should == RubyLint::Definition::Registry::DEFAULT_LOAD_PATH
    end

    it 'adds a path to the load path' do
      @registry.load_path << 'foo'

      @registry.load_path.include?('foo').should == true
    end
  end

  context 'loading constant definitions from the load path' do
    before do
      RubyLint.registry.load('Rational')
    end

    it 'loads the String constant' do
      RubyLint.registry.loaded_constants.include?('Rational').should == true
    end

    it 'registers the String definition' do
      RubyLint.registry.include?('Rational').should == true
    end
  end
end
