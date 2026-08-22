-- Donne à chaque nom de variable une couleur stable et unique, pour repérer
-- d'un coup d'œil "c'est la même variable" partout où elle apparaît dans le
-- fichier — plutôt qu'une coloration uniquement par catégorie syntaxique.

local M = {}

-- Espace de noms dédié pour les marqueurs de couleur posés par ce module
local ns = vim.api.nvim_create_namespace("rainbow_var")

-- Palette de secours utilisée si le thème tokyonight n'est pas disponible
local palette = {
	"#ff757f", "#ff966c", "#ffc777", "#c3e88d", "#4fd6be",
	"#86e1fc", "#82aaff", "#c099ff", "#fca7ea", "#ff007c",
}

-- Requête Treesitter : capture tous les nœuds "identifier" (noms de variables,
-- de fonctions, etc.) du langage du buffer courant
local queries = {
	default = "(identifier) @markid",
}

-- Définit les groupes de coloration RainbowVar1, RainbowVar2, ... à partir
-- de la palette tokyonight active si disponible, sinon de la palette de secours.
-- Refait à chaque changement de thème car les groupes de coloration sont
-- réinitialisés à ce moment-là.
local function set_highlights()
	local ok, colors = pcall(function()
		return require("tokyonight.colors").setup()
	end)
	if ok then
		palette = {
			colors.red, colors.orange, colors.yellow, colors.green, colors.teal,
			colors.cyan, colors.blue, colors.magenta, colors.purple, colors.magenta2,
		}
	end
	for i, color in ipairs(palette) do
		vim.api.nvim_set_hl(0, "RainbowVar" .. i, { fg = color })
	end
end

-- Fonction de hachage simple (variante de djb2) : transforme un nom de
-- variable en nombre. Le même nom donne toujours le même nombre, donc
-- toujours la même couleur — sans avoir à mémoriser d'association quelque part.
local function hash(name)
	local h = 5381
	for i = 1, #name do
		h = (h * 33 + name:byte(i)) % 2147483647
	end
	return h
end

-- Parcourt l'arbre syntaxique du buffer, trouve tous les identifiants, et
-- pose une couleur sur chacun en fonction du hachage de son nom.
local function highlight(bufnr)
	if not vim.api.nvim_buf_is_valid(bufnr) then
		return
	end
	local ok, parser = pcall(vim.treesitter.get_parser, bufnr)
	if not ok or not parser then
		return -- pas de parseur Treesitter pour ce langage : rien à faire
	end

	vim.api.nvim_buf_clear_namespace(bufnr, ns, 0, -1)

	parser:for_each_tree(function(tree, lang_tree)
		local lang = lang_tree:lang()
		local query_str = queries[lang] or queries.default
		local ok_query, query = pcall(vim.treesitter.query.parse, lang, query_str)
		if not ok_query then
			return
		end
		for _, node in query:iter_captures(tree:root(), bufnr, 0, -1) do
			local name = vim.treesitter.get_node_text(node, bufnr)
			if name and name ~= "" then
				local group = "RainbowVar" .. ((hash(name) % #palette) + 1)
				local srow, scol, erow, ecol = node:range()
				pcall(vim.api.nvim_buf_set_extmark, bufnr, ns, srow, scol, {
					end_row = erow,
					end_col = ecol,
					hl_group = group,
					priority = 110,
				})
			end
		end
	end)
end

-- Anti-rebond par buffer : évite de recalculer la coloration à chaque frappe
-- individuelle, en regroupant les changements rapprochés (150ms d'inactivité).
local timers = {}
local function schedule_highlight(bufnr)
	if timers[bufnr] then
		timers[bufnr]:stop()
	else
		timers[bufnr] = vim.uv.new_timer()
	end
	timers[bufnr]:start(150, 0, vim.schedule_wrap(function()
		highlight(bufnr)
	end))
end

-- Active la coloration sur un buffer donné : premier passage immédiat, puis
-- recalcul à chaque modification de texte. Nettoie le minuteur associé
-- quand le buffer est fermé, pour ne pas laisser de tâche en arrière-plan.
local function attach(bufnr)
	local group = vim.api.nvim_create_augroup("rainbow_var_buf_" .. bufnr, { clear = true })
	schedule_highlight(bufnr)
	vim.api.nvim_create_autocmd({ "TextChanged", "TextChangedI", "InsertLeave" }, {
		group = group,
		buffer = bufnr,
		callback = function()
			schedule_highlight(bufnr)
		end,
	})
	-- BufDelete : cas normal de fermeture (":bdelete", et donc "<leader>bc"
	-- / barbar.nvim, qui utilise vim-bbye en interne — un bdelete amélioré,
	-- pas un wipeout). BufWipeout : cas d'un wipeout complet (":bwipeout",
	-- ou à la fermeture de Neovim). Les deux sont gardés : un buffer peut
	-- déclencher l'un puis l'autre selon le contexte, et le nettoyage est
	-- sans risque à exécuter deux fois (rien à faire si déjà fait).
	vim.api.nvim_create_autocmd({ "BufDelete", "BufWipeout" }, {
		group = group,
		buffer = bufnr,
		callback = function()
			if timers[bufnr] then
				timers[bufnr]:stop()
				timers[bufnr]:close()
				timers[bufnr] = nil
			end
		end,
	})
end

function M.setup()
	set_highlights()
	vim.api.nvim_create_autocmd("ColorScheme", { callback = set_highlights })
	vim.api.nvim_create_autocmd({ "BufReadPost", "BufNewFile" }, {
		callback = function(args)
			attach(args.buf)
		end,
	})
end

return M
