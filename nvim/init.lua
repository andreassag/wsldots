-- Starter Neovim configuration for WSL2

vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- UI & line numbers
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.signcolumn = "yes"
vim.opt.cursorline = true
vim.opt.termguicolors = true
vim.opt.scrolloff = 8
vim.opt.updatetime = 250

-- Indentation (4 spaces)
vim.opt.tabstop = 4
vim.opt.softtabstop = 4
vim.opt.shiftwidth = 4
vim.opt.expandtab = true
vim.opt.smartindent = true

-- Search
vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.hlsearch = true
vim.opt.incsearch = true

-- Interaction & files
vim.opt.mouse = "a"
vim.opt.undofile = true
vim.opt.splitright = true
vim.opt.splitbelow = true

-- Clear search highlighting with <Esc> in normal mode
vim.keymap.set("n", "<Esc>", "<cmd>nohlsearch<CR>", { silent = true })

-- WSL2 clipboard integration via clip.exe and powershell.exe
if vim.fn.has("wsl") == 1 and vim.fn.executable("clip.exe") == 1 and vim.fn.executable("powershell.exe") == 1 then
    vim.g.clipboard = {
        name = "WslClipboard",
        copy = {
            ["+"] = "clip.exe",
            ["*"] = "clip.exe",
        },
        paste = {
            ["+"] = 'powershell.exe -NoProfile -NonInteractive -c [Console]::Out.Write(((Get-Clipboard -Raw) -replace "`r", ""))',
            ["*"] = 'powershell.exe -NoProfile -NonInteractive -c [Console]::Out.Write(((Get-Clipboard -Raw) -replace "`r", ""))',
        },
        cache_enabled = 0,
    }
end
