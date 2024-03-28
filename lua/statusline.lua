local M = {}
M.cache = {}

local macro_recording = ""

M.mode_map = {
    ['n'] = { 'Normal', '%#StatuslineModeNormal#' },
    ['v'] = { 'Visual', '%#StatuslineModeVisual#' },
    ['V'] = { 'V·Line', '%#StatuslineModeVisual#' },
    [''] = { 'V·Block', '%#StatuslineModeVisual#' },
    ['s'] = { 'Select', '%#StatuslineModeVisual#' },
    ['S'] = { 'S·Line', '%#StatuslineModeVisual#' },
    [''] = { 'S·Block', '%#StatuslineModeVisual#' },
    ['i'] = { 'Insert', '%#StatuslineModeInsert#' },
    ['R'] = { 'Replace', '%#StatuslineModeReplace#' },
    ['c'] = { 'Command', '%#StatuslineModeCommand#' },
    ['r'] = { 'Prompt', '%#StatuslineModeOther#' },
    ['!'] = { 'Shell', '%#StatuslineModeOther#' },
    ['t'] = { 'Terminal', '%#StatuslineModeOther#' }
}

M.diagnostic_levels = {
    { id = vim.diagnostic.severity.ERROR, sign = 'E' },
    { id = vim.diagnostic.severity.WARN,  sign = 'W' },
    { id = vim.diagnostic.severity.INFO,  sign = 'I' },
    { id = vim.diagnostic.severity.HINT,  sign = 'H' },
}

M.isnt_normal_buffer = function()
    return vim.bo.buftype ~= ''
end

M.create_autocommands = function()
    local augroup = vim.api.nvim_create_augroup('Statusline', {})

    local au = function(event, pattern, callback, desc)
        vim.api.nvim_create_autocmd(event, { group = augroup, pattern = pattern, callback = callback, desc = desc })
    end

    local statusline_redraw = function() vim.wo.statusline = '%!v:lua.Statusline.get_statusline()' end

    au({ 'WinEnter', 'BufEnter', 'InsertEnter' }, '*', statusline_redraw, 'Set active statusline')

    au({ 'RecordingEnter' }, '*', function()
        macro_recording = ' [REC] '
        statusline_redraw()
    end, 'Set macro statusline')

    au({ 'RecordingLeave' }, '*', function()
        macro_recording = ''
        statusline_redraw()
    end, 'Set macro statusline')
end

M.get_diagnostic_count = function(id) return #vim.diagnostic.get(0, { severity = id }) end

M.get_filetype_icon = function()
    if M.cache["icon"] ~= nil then return M.cache["icon"] end
    local has_devicons, devicons = pcall(require, 'nvim-web-devicons')
    if not has_devicons then return '' end

    local file_name, file_ext = vim.fn.expand('%:t'), vim.fn.expand('%:e')
    M.cache["icon"] = devicons.get_icon(file_name, file_ext, { default = true })
    return M.cache["icon"]
end

M.get_filesize = function()
    if M.cache["filesize"] ~= nil then return M.cache["filesize"] end
    local size = vim.fn.getfsize(vim.fn.getreg('%'))
    local out
    if size < 1024 then
        out = string.format('%dB', size)
    elseif size < 1048576 then
        out = string.format('%.2fKiB', size / 1024)
    else
        out = string.format('%.2fMiB', size / 1048576)
    end
    M.cache["filesize"] = out
    return M.cache["filesize"]
end

function M.get_mode()
    local mode = M.mode_map[vim.api.nvim_get_mode().mode] or { "UNKNOWN MODE", "StatuslineModeOther" }
    return mode[2], mode[2] .. ' ' .. mode[1] .. ' '
end

function M.get_filename()
    return '%#StatuslineFilename# %F%m%r '
end

function M.get_fileinfo()
    local filetype = vim.bo.filetype

    if (filetype == '') or M.isnt_normal_buffer() then return '' end

    local icon = M.get_filetype_icon()
    if icon ~= '' then filetype = string.format('%s %s', icon, filetype) end

    local encoding = vim.bo.fileencoding or vim.bo.encoding
    local format = vim.bo.fileformat
    local size = M.get_filesize()

    return string.format('%%#%s# %s %s[%s] %s ', 'StatuslineFileinfo', filetype, encoding, format, size)
end

function M.get_location(hl)
    return (hl or '%#StatusLineNC#') .. ' %l|%2v '
end

function M.get_git_info()
    if M.isnt_normal_buffer() then return '' end

    local head = vim.b.gitsigns_head or ''
    local signs = vim.b.gitsigns_status or vim.b.minidiff_summary_string or ''
    local icon = ''

    if head == '' and signs == '' then return '' end
    return string.format('%%#StatuslineGitInfo# %s%s %s ', icon, head, signs)
end

function M.get_diagnostics()
    if vim.bo.filetype == '' or M.isnt_normal_buffer() then return '' end
    local hasnt_attached_client = next(vim.lsp.buf_get_clients()) == nil
    if hasnt_attached_client then return '' end

    local t = {}
    for _, level in ipairs(M.diagnostic_levels) do
        local n = M.get_diagnostic_count(level.id)
        if n > 0 then table.insert(t, string.format('%s%s', level.sign, n)) end
    end

    local icon = ''
    if vim.tbl_count(t) == 0 then return ('%s - '):format(icon) end
    return string.format('%%#%s#%s %s ', 'StatuslineDiagnostic', icon, table.concat(t, ' '))
end

function M.get_statusline()
    -- local start = vim.loop.hrtime()
    local mode_hl, mode = M.get_mode()
    return macro_recording .. mode ..
        M.get_git_info() ..
        M.get_diagnostics() .. M.get_filename() .. '%=' .. M.get_fileinfo() .. M.get_location(mode_hl)
    -- local finish = vim.loop.hrtime()
    -- print("elapsed: " .. (finish - start) / 1e6 .. "ms")
    -- return out
end

function M.create_default_hl()
    local set_default_hl = function(name, data)
        data.default = true
        vim.api.nvim_set_hl(0, name, data)
    end

    set_default_hl('StatuslineModeNormal', { link = 'Cursor' })
    set_default_hl('StatuslineModeInsert', { link = 'DiffChange' })
    set_default_hl('StatuslineModeVisual', { link = 'DiffAdd' })
    set_default_hl('StatuslineModeReplace', { link = 'DiffDelete' })
    set_default_hl('StatuslineModeCommand', { link = 'DiffText' })
    set_default_hl('StatuslineModeOther', { link = 'IncSearch' })

    set_default_hl('StatuslineGitInfo', { link = 'StatusLine' })
    set_default_hl('StatuslineDiagnostic', { link = 'StatusLine' })
    set_default_hl('StatuslineFilename', { link = 'StatusLineNC' })
    set_default_hl('StatuslineFileinfo', { link = 'StatusLine' })
end

function M.setup()
    _G.Statusline = M
    M.create_autocommands()
    vim.g.qf_disable_statusline = 1
    M.create_default_hl()
end

return M
