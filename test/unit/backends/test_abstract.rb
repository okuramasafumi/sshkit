require 'helper'

module SSHKit

  module Backend

    class TestAbstract < UnitTest

      def test_make
        backend = ExampleBackend.new do
          make %w(some command)
        end

        backend.run

        assert_equal '/usr/bin/env make some command', backend.executed_command.to_command
      end

      def test_rake
        backend = ExampleBackend.new do
          rake %w(a command)
        end

        backend.run

        assert_equal '/usr/bin/env rake a command', backend.executed_command.to_command
      end

      def test_execute_creates_and_executes_command_with_default_options
        backend = ExampleBackend.new do
          execute :ls, '-l', '/some/directory'
        end

        backend.run

        assert_equal '/usr/bin/env ls -l /some/directory', backend.executed_command.to_command
        assert_equal(
          {:raise_on_non_zero_exit=>true, :run_in_background=>false, :in=>nil, :env=>nil, :host=>ExampleBackend.example_host, :user=>nil, :group=>nil},
          backend.executed_command.options
        )
      end

      def test_test_method_creates_and_executes_command_with_false_raise_on_non_zero_exit
        backend = ExampleBackend.new do
          test '[ -d /some/file ]'
        end

        backend.run

        assert_equal '[ -d /some/file ]', backend.executed_command.to_command
        assert_equal false, backend.executed_command.options[:raise_on_non_zero_exit], 'raise_on_non_zero_exit option'
      end

      def test_capture_creates_and_executes_command_and_returns_output
        output = nil
        backend = ExampleBackend.new do
          output = capture :cat, '/a/file'
        end
        backend.full_stdout = 'Some stdout'

        backend.run

        assert_equal '/usr/bin/env cat /a/file', backend.executed_command.to_command
        assert_equal 'Some stdout', output
      end

      def test_calling_abstract_with_undefined_execute_command_raises_exception
        abstract =  Abstract.new(ExampleBackend.example_host) do
          execute(:some_command)
        end

        assert_raises(SSHKit::Backend::MethodUnavailableError) do
          abstract.run
        end
      end

      def test_abstract_backend_can_be_configured
        Abstract.configure do |config|
          config.some_option = 100
        end

        assert_equal 100, Abstract.config.some_option
      end

      def test_invoke_raises_no_method_error
        assert_raises NoMethodError do
          ExampleBackend.new.invoke :echo
        end
      end

      private

      # Use a concrete ExampleBackend rather than a mock for improved assertion granularity
      class ExampleBackend < Abstract
        attr_writer :full_stdout
        attr_reader :executed_command

        def initialize(&block)
          block = block.nil? ? lambda {} : block
          super(ExampleBackend.example_host, &block)
        end

        def execute_command(command)
          @executed_command = command
          command.full_stdout = @full_stdout
        end

        def ExampleBackend.example_host
          Host.new(:'example.com')
        end

      end

    end

  end

end
