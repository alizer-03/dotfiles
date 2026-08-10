local M = {}

-- Espace de noms dédié pour les diagnostics norminette, pour ne pas les
-- confondre avec ceux de clangd (LSP) ni pouvoir les effacer par erreur
local ns = vim.api.nvim_create_namespace("norminette")
local enabled = true
local timer
local job

-- Transforme la sortie texte de norminette en diagnostics Neovim.
-- Format attendu par ligne : "Error: TYPE (line: N, col: N): message"
local function parse(output, bufnr)
	local diags = {}
	for raw in output:gmatch("[^\r\n]+") do
		local line = raw:gsub("\27%[[%d;]*m", "") -- retire les codes couleur ANSI éventuels
		local kind, code, lnum, col, msg = line:match("^(%a+):%s+(%S+)%s+%(line:%s*(%d+),%s+col:%s*(%d+)%):%s*(.+)$")
		if code then
			-- norminette compte les lignes/colonnes à partir de 1, Neovim à partir de 0
			local l = math.max((tonumber(lnum) or 1) - 1, 0)
			local c = math.max((tonumber(col) or 1) - 1, 0)
			table.insert(diags, {
				bufnr = bufnr,
				lnum = l,
				end_lnum = l,
				col = c,
				end_col = c + 1,
				severity = (kind == "Notice") and vim.diagnostic.severity.WARN or vim.diagnostic.severity.ERROR,
				source = "norminette",
				code = code,
				message = (msg:gsub("^%s+", ""):gsub("%s+$", "")),
			})
		end
	end
	return diags
end

-- Lance norminette en tâche de fond sur le fichier du buffer donné, et met
-- à jour les diagnostics une fois le résultat reçu (asynchrone, ne bloque
-- jamais la saisie).
local function run(bufnr)
	bufnr = (bufnr and bufnr ~= 0) and bufnr or vim.api.nvim_get_current_buf()
	if not enabled or not vim.api.nvim_buf_is_valid(bufnr) then
		return
	end
	local name = vim.api.nvim_buf_get_name(bufnr)
	if not name:match("%.[ch]$") then
		return -- ne s'exécute que sur les fichiers .c/.h
	end
	if vim.fn.executable("norminette") == 0 then
		return -- outil non installé : on abandonne silencieusement plutôt que d'afficher une erreur à chaque frappe
	end

	-- si une exécution précédente est encore en cours, on l'annule : seul le
	-- dernier état du fichier nous intéresse
	if job then
		pcall(function()
			job:kill(9)
		end)
		job = nil
	end

	job = vim.system(
		{ "norminette", name },
		{ text = true, timeout = 5000, env = { NO_COLOR = "1" } },
		vim.schedule_wrap(function(res)
			job = nil
			if not vim.api.nvim_buf_is_valid(bufnr) then
				return
			end
			local out = (res.stdout or "") .. "\n" .. (res.stderr or "")
			vim.diagnostic.set(ns, bufnr, parse(out, bufnr))
		end)
	)
end

-- Anti-rebond (debounce) : regroupe les déclenchements rapprochés (ex. plusieurs
-- sauvegardes en peu de temps) en une seule exécution, 400ms après la dernière.
-- Évite de relancer norminette à chaque frappe/sauvegarde si elles s'enchaînent vite.
local function schedule(bufnr)
	if timer then
		timer:stop()
		pcall(function()
			timer:close()
		end)
	end
	local t = vim.uv.new_timer()
	timer = t
	t:start(400, 0, function()
		t:stop()
		pcall(function()
			t:close()
		end)
		if timer == t then
			timer = nil
		end
		vim.schedule(function()
			run(bufnr)
		end)
	end)
end

function M.setup()
	local grp = vim.api.nvim_create_augroup("NorminetteAsync", { clear = true })
	-- déclenche une vérification à l'ouverture et à chaque sauvegarde d'un fichier C/H
	vim.api.nvim_create_autocmd({ "BufReadPost", "BufWritePost" }, {
		group = grp,
		pattern = { "*.c", "*.h" },
		callback = function(args)
			schedule(args.buf)
		end,
	})

	-- commandes manuelles, utiles pour forcer une vérification ou débrayer temporairement
	vim.api.nvim_create_user_command("Norminette", function()
		run(0)
	end, { desc = "Run norminette on the current C file" })

	vim.api.nvim_create_user_command("NorminetteClear", function()
		vim.diagnostic.reset(ns, 0)
	end, { desc = "Clear norminette diagnostics" })

	vim.api.nvim_create_user_command("NorminetteToggle", function()
		enabled = not enabled
		if not enabled then
			vim.diagnostic.reset(ns)
		else
			run(0)
		end
		vim.notify("norminette " .. (enabled and "enabled" or "disabled"))
	end, { desc = "Toggle norminette diagnostics on save" })
end

return M