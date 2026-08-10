local M = {}

M.get_server_list = function()
	return { "clangd", "pyright", "ruff", "html", "cssls", "ts_ls", "eslint" }
end

M.setup_server_configs = function()
	-- C ---------------------------------------------------------------------
	-- Chemin absolu vers le clangd installé par Mason plutôt qu'un simple nom
	-- de commande : évite que Neovim aille chercher un autre clangd déjà
	-- présent sur le système (par exemple celui des outils Apple sur macOS),
	-- qui peut avoir un support incomplet de certaines fonctionnalités.
	local clangd_path = vim.fn.stdpath("data") .. "/mason/bin/clangd"

	vim.lsp.config("clangd", {
		cmd = {
			clangd_path,
			"--background-index", -- indexe tout le projet en arrière-plan
			"--clang-tidy", -- active les vérifications supplémentaires de clang-tidy
			"--header-insertion=never", -- n'ajoute jamais un #include automatiquement à la complétion
		},
		filetypes = { "c", "cpp", "objc", "objcpp" },
		root_markers = { "Makefile", "compile_commands.json", ".clangd", ".git" },
		init_options = {
			-- drapeaux utilisés en l'absence de compile_commands.json, utile
			-- pour analyser un fichier isolé hors d'un projet complet
			fallbackFlags = { "-Wall", "-Wextra" },
		},
	})

	-- Python (Python/IA) ------------------------------------------------------
	-- Analyse de types, complétion, navigation (aller à la définition, hover)
	vim.lsp.config("pyright", {
		settings = {
			python = {
				analysis = {
					-- vérification "basique" plutôt que "stricte" : signale les
					-- erreurs évidentes sans être trop exigeant pour de l'apprentissage
					typeCheckingMode = "basic",
				},
			},
		},
	})

	-- Linter rapide (imports inutilisés, variables non utilisées, etc.) —
	-- complémentaire à pyright, pas redondant : pyright vérifie les types,
	-- ruff vérifie le style et les erreurs évidentes
	vim.lsp.config("ruff", {})

	-- Web (HTML / CSS / JavaScript / TypeScript) -----------------------------
	-- Configuration par défaut suffisante pour ces trois serveurs (filetypes
	-- et racine de projet déjà couverts par leurs réglages standards)
	vim.lsp.config("html", {})
	vim.lsp.config("cssls", {})
	vim.lsp.config("ts_ls", {})

	-- Linter JS/TS — ne signale des erreurs que si le projet contient un
	-- fichier de config ESLint (.eslintrc.json, eslint.config.js, etc.) ;
	-- sans ça, il reste silencieux, ce n'est pas un signe de mauvais réglage
	vim.lsp.config("eslint", {})
end

return M