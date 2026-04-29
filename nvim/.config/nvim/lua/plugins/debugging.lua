return {
  'mfussenegger/nvim-dap',
  dependencies = {
    'rcarriga/nvim-dap-ui',
    'leoluz/nvim-dap-go',
    'nvim-neotest/nvim-nio',
  },
  keys = {
    { '<leader>dt', function() require('dap').toggle_breakpoint() end, desc = "Toggle Breakpoint" },
    { '<leader>dc', function() require('dap').continue() end, desc = "Continue" },
    { '<leader>di', function() require('dap').step_into() end, desc = "Step Into" },
    { '<leader>do', function() require('dap').step_over() end, desc = "Step Over" },
    { '<leader>dO', function() require('dap').step_out() end, desc = "Step Out" },
    { '<leader>dr', function() require('dap').repl.open() end, desc = "Open REPL" },
    { '<leader>du', function() require('dapui').toggle() end, desc = "Toggle DAP UI" },
  },
  config = function()
    local dap = require('dap')
    local dapui = require('dapui')

    require('dapui').setup()
    require('dap-go').setup()

    dap.listeners.before.attach.dapui_config = function()
      dapui.open()
    end
    dap.listeners.before.launch.dapui_config = function()
      dapui.open()
    end
    dap.listeners.before.event_terminated.dapui_config = function()
      dapui.close()
    end
    dap.listeners.before.event_exited.dapui_config = function()
      dapui.close()
    end
  end
}