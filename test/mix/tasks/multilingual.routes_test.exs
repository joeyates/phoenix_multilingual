defmodule Mix.Tasks.Multilingual.RoutesTest do
  use ExUnit.Case, async: true

  @moduletag :integration

  setup_all do
    root = File.cwd!()
    test_path = Path.join([root, "test", "support", "project"])
    env = [{"MIX_ENV", "dev"}]

    File.cd!(test_path, fn ->
      {_clean_output, 0} = System.cmd("git", ["clean", "-ffdx"])
      {_deps_output, 0} = System.cmd("mix", ["deps.get"], env: env, stderr_to_stdout: true)
      {_compile_output, 0} = System.cmd("mix", ["compile"], env: env, stderr_to_stdout: true)
    end)

    on_exit(fn ->
      File.cd!(test_path, fn ->
        {_clean_output, 0} = System.cmd("git", ["clean", "-ffdx"])
      end)
    end)

    %{env: env, test_path: test_path}
  end

  test "it lists views", %{env: env, test_path: test_path} do
    Mix.Project.in_project(:my_app, test_path, fn _module ->
      {output, 0} = System.cmd("mix", ["multilingual.routes"], env: env, stderr_to_stdout: true)
      assert output =~ ~r(method\s+module\s+view)
    end)
  end

  test "it has columns for each locale", %{env: env, test_path: test_path} do
    Mix.Project.in_project(:my_app, test_path, fn _module ->
      {output, 0} = System.cmd("mix", ["multilingual.routes"], env: env, stderr_to_stdout: true)
      assert output =~ ~r(en\s+it)
    end)
  end
end
