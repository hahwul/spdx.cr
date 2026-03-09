require "./spdx"
require "./spdx/cli/commands/expression"
require "./spdx/cli/commands/license"
require "./spdx/cli/commands/validate"
require "./spdx/cli/commands/convert"
require "./spdx/cli/app"

Spdx::CLI::App.new.run
