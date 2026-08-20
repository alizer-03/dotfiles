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
		local code, lnum, col, msg = line:match("^%a+:%s+(%S+)%s+%(line:%s*(%d+),%s+col:%s*(%d+)%):%s*(.+)$")
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
				-- norminette n'émet en pratique que des "Error:" (pas de sévérité
				-- distincte type "Notice"/warning observée dans ses sorties réelles)
				severity = vim.diagnostic.severity.ERROR,
				source = "norminette",
				code = code,
				message = (msg:gsub("^%s+", ""):gsub("%s+$", "")),
			})
		end
	end
	return diags
end

-- Centralise les conditions qui décident si norminette doit tourner sur ce
-- buffer, et pourquoi sinon — utilisé en silence par le déclenchement
-- automatique (schedule/run), et pour donner un vrai message d'explication
-- à la commande manuelle :Norminette.
local function why_not(bufnr)
	if not enabled then
		return "désactivé (:NorminetteToggle)"
	end
	if not vim.api.nvim_buf_is_valid(bufnr) then
		return "buffer invalide"
	end
	local name = vim.api.nvim_buf_get_name(bufnr)
	if not name:match("%.[ch]$") then
		return "pas un fichier .c/.h"
	end
	if not name:match("/42/") then
		-- ne s'applique qu'aux projets situés dans un dossier "42" (norme propre à
		-- ce cursus) ; ailleurs, un formateur classique (clang-format) prend le relais
		return 'hors d\'un dossier "42"'
	end
	if vim.fn.executable("norminette") == 0 then
		return "norminette introuvable dans le PATH"
	end
	return nil
end

-- Lance norminette en tâche de fond sur le fichier du buffer donné, et met
-- à jour les diagnostics une fois le résultat reçu (asynchrone, ne bloque
-- jamais la saisie). Silencieux si les conditions de why_not() ne sont pas
-- réunies : comportement voulu pour le déclenchement automatique.
local function run(bufnr)
	bufnr = (bufnr and bufnr ~= 0) and bufnr or vim.api.nvim_get_current_buf()
	if why_not(bufnr) then
		return
	end
	local name = vim.api.nvim_buf_get_name(bufnr)

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

-- Relance run() sur tous les buffers chargés (utilisé par NorminetteToggle à
-- la réactivation, pour rafraîchir tous les fichiers ouverts et pas
-- seulement celui affiché à l'instant — symétrique avec la désactivation,
-- qui efface les diagnostics de tous les buffers d'un coup)
local function run_all()
	for _, buf in ipairs(vim.api.nvim_list_bufs()) do
		if vim.api.nvim_buf_is_loaded(buf) then
			run(buf)
		end
	end
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
	-- (le filtre de dossier "42/" est appliqué dans run(), pas ici, pour rester
	-- le seul endroit qui décide si le fichier est concerné)
	vim.api.nvim_create_autocmd({ "BufReadPost", "BufWritePost" }, {
		group = grp,
		pattern = { "*.c", "*.h" },
		callback = function(args)
			schedule(args.buf)
		end,
	})

	-- commandes manuelles, utiles pour forcer une vérification ou débrayer temporairement
	vim.api.nvim_create_user_command("Norminette", function()
		local bufnr = vim.api.nvim_get_current_buf()
		local reason = why_not(bufnr)
		if reason then
			vim.notify("norminette : rien à faire (" .. reason .. ")", vim.log.levels.WARN)
			return
		end
		run(bufnr)
	end, { desc = "Run norminette on the current C file" })

	vim.api.nvim_create_user_command("NorminetteClear", function()
		vim.diagnostic.reset(ns, 0)
	end, { desc = "Clear norminette diagnostics" })

	vim.api.nvim_create_user_command("NorminetteToggle", function()
		enabled = not enabled
		if not enabled then
			vim.diagnostic.reset(ns)
		else
			run_all()
		end
		vim.notify("norminette " .. (enabled and "enabled" or "disabled"))
	end, { desc = "Toggle norminette diagnostics on save" })
end

return M