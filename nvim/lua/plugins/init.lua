-- ============================================================================
-- Spécifications des plugins (lazy.nvim)
-- Chaque bloc = un plugin. "event"/"cmd"/"ft"/"keys" définissent QUAND il se
-- charge (lazy loading) ; "opts"/"config" définissent COMMENT il se configure.
-- ============================================================================

return {

	-- Complétion (autocomplétion LSP, snippets, chemins de fichiers, buffer)
	{
		"saghen/blink.cmp",
		version = "1.*",
		event = "InsertEnter", -- ne se charge qu'en entrant en mode Insertion
		dependencies = { "L3MON4D3/LuaSnip" },
		opts = {
			enabled = function()
				local ft = vim.bo[0].filetype
				-- désactive la complétion dans la barre de recherche des pickers Snacks
				if ft == "snacks_picker_input" then
					return false
				end
				return true
			end,
			sources = {
				default = { "lsp", "path", "snippets", "buffer" },
			},
			snippets = {
				preset = "luasnip",
				expand = function(snippet)
					require("luasnip").lsp_expand(snippet)
				end,
				active = function(filter)
					if filter and filter.direction then
						return require("luasnip").jumpable(filter.direction)
					end
					return require("luasnip").in_snippet()
				end,
				jump = function(direction)
					require("luasnip").jump(direction)
				end,
			},
			completion = {
				menu = { border = "single" },
				documentation = { auto_show = true, window = { border = "single" } },
				ghost_text = { enabled = true }, -- aperçu du texte accepté, en grisé
			},
			cmdline = {
				-- sources différentes selon le type de ligne de commande (:, /, ?)
				sources = function()
					local t = vim.fn.getcmdtype()
					if t == "/" or t == "?" then
						return { "buffer" }
					end
					if t == ":" then
						return { "cmdline" }
					end
					return {}
				end,
			},
			keymap = {
				preset = "default",
				["<Tab>"] = { "snippet_forward", "select_next", "fallback" },
				["<S-Tab>"] = { "snippet_backward", "select_prev", "fallback" },
				["<C-p>"] = { "select_prev", "fallback" },
				["<C-n>"] = { "select_next", "fallback" },
				["<C-space>"] = { "show", "show_documentation", "hide_documentation" },
				["<C-e>"] = { "hide", "fallback" },
				["<CR>"] = { "accept", "fallback" },
				["<C-y>"] = { "accept", "fallback" },
				["<Esc>"] = { "cancel", "fallback" },
			},
		},
	},

	-- Pont générique entre Neovim et les serveurs LSP (utilisé par clangd)
	{
		"neovim/nvim-lspconfig",
		event = { "BufReadPre", "BufNewFile" },
		dependencies = { "saghen/blink.cmp" },
		config = function()
			-- étend les capacités LSP par défaut avec celles de blink.cmp
			-- (sinon le serveur ne sait pas que Neovim sait gérer les snippets, etc.)
			local caps = require("blink.cmp").get_lsp_capabilities()
			vim.lsp.config("*", {
				capabilities = caps,
				on_attach = function(_, bufnr)
					vim.api.nvim_buf_set_option(bufnr, "omnifunc", "v:lua.vim.lsp.omnifunc")
				end,
			})
			require("lsp.servers").setup_server_configs()
		end,
	},

	-- Gestionnaire de paquets : installe et met à jour les serveurs LSP/linters/formateurs
	{
		"williamboman/mason.nvim",
		cmd = "Mason", -- ne se charge qu'à l'appel de :Mason (mais aussi tiré comme dépendance)
		build = ":MasonUpdate",
		opts = {
			ui = {
				border = "rounded",
				icons = {
					package_installed = "✓",
					package_pending = "➜",
					package_uninstalled = "✗",
				},
			},
		},
	},

	-- Pont entre mason.nvim et nvim-lspconfig : installe clangd puis l'active
	{
		"williamboman/mason-lspconfig.nvim",
		event = { "BufReadPre", "BufNewFile" },
		dependencies = { "williamboman/mason.nvim", "neovim/nvim-lspconfig" },
		opts = function()
			return {
				ensure_installed = require("lsp.servers").get_server_list(), -- { "clangd" }
				automatic_installation = true,
			}
		end,
		config = function(_, opts)
			require("mason-lspconfig").setup(opts)
			-- vim.schedule : on attend que Neovim ait fini son cycle de démarrage
			-- avant d'activer les serveurs, pour éviter les effets de bord
			vim.schedule(function()
				for _, name in ipairs(opts.ensure_installed) do
					pcall(vim.lsp.enable, name)
				end
			end)
		end,
	},

	-- Analyse syntaxique (coloration précise, indentation, pliage de code)
	{
		"nvim-treesitter/nvim-treesitter",
		branch = "main",
		build = ":TSUpdate",
		event = { "BufReadPost", "BufNewFile" },
		config = function()
			require("nvim-treesitter").setup()
			-- parseurs installés : C/Lua (existant) + Python, HTML, CSS, JavaScript,
			-- TypeScript (langages hors C : Python/IA et Web)
			require("nvim-treesitter").install({
				"c", "lua", "python", "html", "css", "javascript", "typescript",
			})

			-- active treesitter uniquement sur les filetypes couverts ci-dessus
			vim.api.nvim_create_autocmd("FileType", {
				callback = function(args)
					local langs = {
						c = true,
						lua = true,
						python = true,
						html = true,
						css = true,
						javascript = true,
						typescript = true,
					}
					if langs[args.match] then
						pcall(vim.treesitter.start)
						vim.bo[args.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
					end
				end,
			})

			-- pliage de code basé sur la structure syntaxique plutôt que l'indentation
			vim.opt.foldmethod = "expr"
			vim.opt.foldexpr = "v:lua.vim.treesitter.foldexpr()"
			vim.opt.foldlevel = 99 -- tout est déplié à l'ouverture d'un fichier
		end,
	},

	-- Colore les paires de délimiteurs ( ) [ ] { } selon leur profondeur d'imbrication
	{
		"HiPhish/rainbow-delimiters.nvim",
		event = "BufReadPost",
	},

	-- Génère et met à jour le header standard 42 (commande :Stdheader, touche F1)
	{
		"Diogo-ss/42-header.nvim",
		cmd = { "Stdheader" },
		keys = { "<F1>" },
		opts = {
			default_map = true,
			auto_update = true, -- met à jour "Updated:" à chaque sauvegarde
			-- pas besoin de "user"/"mail" ici : le plugin lit directement
			-- vim.g.user/vim.g.mail (définis dans core/options.lua) en
			-- priorité maximale, avant même les variables d'environnement
		},
		config = function(_, opts)
			require("42header").setup(opts)
		end,
	},

	-- Moteur de snippets + snippets maison pour la piscine 42
	{
		"L3MON4D3/LuaSnip",
		version = "v2.*",
		config = function()
			local ls = require("luasnip")
			local ok, fortytwo = pcall(require, "snippets.fortytwo")
			if ok then
				ls.add_snippets("c", fortytwo.c)
				ls.add_snippets("make", fortytwo.make)
				ls.add_snippets("python", fortytwo.python)
				ls.add_snippets("html", fortytwo.html)
			end
		end,
	},

	-- Améliore la lisibilité du C : indices de type/paramètres en ligne (inlay hints),
	-- vue de l'AST (:ClangdAST), et retouche de la coloration sémantique de clangd
	{
		"p00f/clangd_extensions.nvim",
		ft = "c",
		opts = {
			inlay_hints = {
				inline = true,
				only_current_line = false,
				show_parameter_hints = true,
				parameter_hints_prefix = "<- ",
				other_hints_prefix = "=> ",
			},
			ast = {
				role_icons = {
					type = "",
					declaration = "",
					expression = "",
					statement = ";",
					specifier = "",
					["template argument"] = "",
				},
				kind_icons = {
					Compound = "",
					Recovery = "",
					TranslationUnit = "",
					PackExpansion = "",
					TemplateTypeParm = "",
					TemplateTemplateParm = "",
					TemplateParamObject = "",
				},
			},
		},
		config = function(_, opts)
			require("clangd_extensions").setup(opts)

			-- active les inlay hints seulement sur les buffers C (pas partout)
			vim.api.nvim_create_autocmd("LspAttach", {
				callback = function(args)
					if vim.bo[args.buf].filetype == "c" then
						pcall(vim.lsp.inlay_hint.enable, true, { bufnr = args.buf })
					end
				end,
			})

			-- retouche certains groupes de coloration sémantique (clangd) pour qu'ils
			-- ressortent mieux avec le thème Catppuccin (italique/gras ajoutés)
			local function tune_semantic_tokens()
				local function based_on(group, base, extra)
					local base_hl = vim.api.nvim_get_hl(0, { name = base, link = false })
					vim.api.nvim_set_hl(0, group, vim.tbl_extend("force", base_hl, extra or {}))
				end
				based_on("@lsp.typemod.variable.readonly", "@constant", { italic = true })
				based_on("@lsp.type.macro", "@constant.macro", { bold = true })
				based_on("@lsp.typemod.function.defaultLibrary", "@function.builtin", { italic = true })
				vim.api.nvim_set_hl(0, "@lsp.type.property", { link = "@variable.member" })
			end

			tune_semantic_tokens()
			-- refaire la retouche à chaque changement de thème (les groupes sont recréés)
			vim.api.nvim_create_autocmd("ColorScheme", {
				callback = tune_semantic_tokens,
			})
		end,
	},

	-- Colore les paramètres de fonction (les distingue visuellement des variables)
	{
		"m-demare/hlargs.nvim",
		event = { "BufReadPost", "BufNewFile" },
		dependencies = { "nvim-treesitter/nvim-treesitter", "catppuccin/nvim" },
		opts = function()
			-- va chercher une couleur directement dans la palette Catppuccin active,
			-- avec une couleur de repli si jamais la palette n'est pas disponible
			local ok, palette = pcall(function()
				return require("catppuccin.palettes").get_palette("mocha")
			end)
			return {
				color = (ok and palette.peach) or "#e0af68",
				highlight = { bold = true }, -- compense le faible contraste de la palette pastel
				excluded_filetypes = { "markdown", "text", "help", "sh", "bash", "make" },
			}
		end,
	},

	-- Thème de couleurs (Catppuccin Mocha)
	{
		"catppuccin/nvim",
		name = "catppuccin",
		lazy = false, -- chargé au démarrage : c'est le thème, il doit être prêt tout de suite
		priority = 1000, -- chargé avant tous les autres plugins non-lazy
		opts = {
			flavour = "mocha", -- variante sombre et douce de la palette Catppuccin
			transparent_background = false,
			show_end_of_buffer = false,
			term_colors = true,
			styles = {
				comments = { "italic" },
				conditionals = { "italic" },
			},
			integrations = {
				blink_cmp = true,
				treesitter = true,
				mason = true,
				native_lsp = { enabled = true },
			},
		},
		config = function(_, opts)
			require("catppuccin").setup(opts)
			vim.cmd.colorscheme("catppuccin-mocha")
		end,
	},

	-- Icônes de fichiers (utilisé par snacks.nvim pour l'explorateur/les pickers)
	{
		"echasnovski/mini.icons",
		version = false,
		opts = {},
	},

	-- Suite d'utilitaires : tableau de bord, explorateur de fichiers, pickers
	-- (recherche floue de fichiers/texte/buffers/diagnostics/etc.), LazyGit intégré
	{
		"folke/snacks.nvim",
		priority = 1000,
		lazy = false,
		opts = {
			bigfile = { enabled = true, auto_disable_lsp = true, auto_disable_treesitter = true },
			explorer = { enabled = true },
			picker = { enabled = true },
			dashboard = {
				enabled = true,
				sections = {
					{ section = "header" },
					{ section = "keys", gap = 1, padding = 1 },
					{ icon = " ", title = "Recent Files", section = "recent_files", indent = 2, padding = 1 },
					{ icon = " ", title = "Projects", section = "projects", indent = 2, padding = 1 },
					{
						icon = " ",
						title = "Git Status",
						section = "terminal",
						enabled = vim.fn.isdirectory(".git") == 1,
						cmd = "git status --short --branch",
						height = 5,
						padding = 1,
						ttl = 5 * 60,
						indent = 3,
					},
					{ section = "startup" },
				},
			},
		},
		keys = {
			-- Recherche / navigation de fichiers
			{ "<leader>ff", function() Snacks.picker.files() end, desc = "Trouver un fichier" },
			{ "<leader>fg", function() Snacks.picker.grep() end, desc = "Chercher dans le contenu" },
			{ "<leader>fb", function() Snacks.picker.buffers() end, desc = "Buffers ouverts" },
			{ "<leader>fr", function() Snacks.picker.recent() end, desc = "Fichiers récents" },
			{ "<leader>e", function() Snacks.explorer() end, desc = "Explorateur de fichiers" },

			-- Git
			{ "<leader>gg", function() Snacks.lazygit() end, desc = "LazyGit" },
			{ "<leader>gl", function() Snacks.picker.git_log() end, desc = "Historique des commits" },
			{ "<leader>gd", function() Snacks.picker.git_diff() end, desc = "Diff Git" },

			-- Introspection Neovim (sous-ensemble volontairement réduit à l'essentiel)
			{ "<leader>sd", function() Snacks.picker.diagnostics() end, desc = "Diagnostics du projet" },
			{ "<leader>sh", function() Snacks.picker.help() end, desc = "Aide Neovim (:help)" },
			{ "<leader>sH", function() Snacks.picker.highlights() end, desc = "Groupes de couleur actifs" },
			{ "<leader>sk", function() Snacks.picker.keymaps() end, desc = "Raccourcis définis" },
			{ "<leader>su", function() Snacks.picker.undo() end, desc = "Historique d'annulation" },
			{ "<leader>sM", function() Snacks.picker.man() end, desc = "Pages man" },
		},
	},

	-- Interface LSP avancée : arbre des symboles, références/définitions,
	-- actions de code et renommage dans des fenêtres flottantes
	{
		"nvimdev/lspsaga.nvim",
		event = "LspAttach", -- se charge dès qu'un serveur LSP s'attache à un buffer
		dependencies = { "nvim-treesitter/nvim-treesitter", "catppuccin/nvim" },
		opts = function()
			-- récupère le thème d'icônes Catppuccin pour le menu "code action" ;
			-- pcall par sécurité si l'intégration n'est pas disponible
			local ok, kind = pcall(function()
				return require("catppuccin.groups.integrations.lsp_saga").custom_kind()
			end)
			return {
				ui = {
					kind = ok and kind or nil,
				},
			}
		end,
		config = function(_, opts)
			require("lspsaga").setup(opts)
		end,
	},

	-- Signes Git en marge (ajout/modification/suppression), navigation et
	-- gestion des hunks (portions de changement) directement dans le buffer
	{
		"lewis6991/gitsigns.nvim",
		event = { "BufReadPre", "BufNewFile" },
		opts = {
			-- raccourcis propres au buffer, définis uniquement une fois gitsigns attaché
			on_attach = function(bufnr)
				local gs = require("gitsigns")

				-- navigation entre hunks ; repli sur ]c/[c natifs si on est en mode diff
				vim.keymap.set("n", "]h", function()
					if vim.wo.diff then
						return "]c"
					end
					vim.schedule(gs.next_hunk)
					return "<Ignore>"
				end, { buffer = bufnr, expr = true, desc = "Hunk suivant" })

				vim.keymap.set("n", "[h", function()
					if vim.wo.diff then
						return "[c"
					end
					vim.schedule(gs.prev_hunk)
					return "<Ignore>"
				end, { buffer = bufnr, expr = true, desc = "Hunk précédent" })

				vim.keymap.set("n", "<leader>hs", gs.stage_hunk, { buffer = bufnr, desc = "Stage le hunk" })
				vim.keymap.set("n", "<leader>hr", gs.reset_hunk, { buffer = bufnr, desc = "Annule le hunk" })
				vim.keymap.set("n", "<leader>hp", gs.preview_hunk, { buffer = bufnr, desc = "Aperçu du hunk" })
			end,
		},
	},

	-- Formatage de code à la demande — volontairement PAS automatique à la
	-- sauvegarde, pour rester cohérent avec la prudence gardée côté C (où le
	-- formateur norme 42 n'a jamais été ajouté faute d'être vérifié).
	-- Ici les formateurs (ruff format, prettier) sont des standards matures
	-- et déterministes, donc le risque est différent — mais le déclenchement
	-- reste manuel par choix, pas par nécessité technique.
	{
		"stevearc/conform.nvim",
		cmd = "ConformInfo",
		keys = {
			{
				"<leader>cf",
				function()
					require("conform").format({ lsp_fallback = true })
				end,
				desc = "Formater le buffer",
			},
		},
		opts = {
			formatters_by_ft = {
				python = { "ruff_format" },
				javascript = { "prettier" },
				typescript = { "prettier" },
				html = { "prettier" },
				css = { "prettier" },
			},
		},
		config = function(_, opts)
			-- prettier n'est pas un serveur LSP : mason-lspconfig ne l'installe
			-- pas automatiquement (voir plus haut, ensure_installed ne couvre
			-- que les serveurs LSP) — on s'en charge nous-mêmes ici, une seule fois
			local ok, registry = pcall(require, "mason-registry")
			if ok and registry.has_package("prettier") then
				local pkg = registry.get_package("prettier")
				if not pkg:is_installed() then
					pkg:install()
				end
			end
			require("conform").setup(opts)
		end,
	},

	-- Affiche un panneau flottant listant les touches disponibles dès qu'on
	-- commence une séquence de raccourcis (ex. taper la touche leader puis
	-- attendre) — sert d'aide-mémoire visuel pour tous les raccourcis définis
	-- dans cette configuration, sans avoir à les connaître par cœur.
	{
		"folke/which-key.nvim",
		event = "VeryLazy", -- se charge juste après le démarrage, sans ralentir l'ouverture de Neovim
		opts = {
			-- Noms de groupe affichés pour chaque préfixe de raccourcis, plutôt
			-- que de laisser which-key deviner ou afficher juste la lettre brute
			spec = {
				{ "<leader>f", group = "Fichiers" },
				{ "<leader>s", group = "Introspection Neovim" },
				{ "<leader>g", group = "Git" },
				{ "<leader>l", group = "LSP" },
				{ "<leader>h", group = "Hunks Git" },
				{ "<leader>c", group = "Code" },
			},
		},
	},
}