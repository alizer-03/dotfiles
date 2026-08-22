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
		event = { "InsertEnter", "CmdlineEnter" }, -- charge aussi dès l'ouverture de la ligne de commande, pas seulement en Insertion
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
				ensure_installed = require("lsp.servers").get_server_list(), -- clangd, pyright, ruff, html, cssls, ts_ls, eslint, lua_ls
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

	-- Affiche la progression des serveurs LSP (indexation, analyse) dans un
	-- coin de l'écran — jusqu'ici aucun retour visuel pendant ce temps de
	-- charge, aucun moyen de savoir si clangd/pyright ont fini d'indexer.
	{
		"j-hui/fidget.nvim",
		event = "LspAttach",
		opts = {},
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
			-- TypeScript (langages hors C : Python/IA et Web) + bash/json/markdown
			-- (scripts, configs et rendu via render-markdown.nvim ci-dessous)
			require("nvim-treesitter").install({
				"c", "lua", "python", "html", "css", "javascript", "typescript",
				"bash", "json", "markdown", "markdown_inline",
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
						bash = true,
						json = true,
						markdown = true,
						markdown_inline = true,
					}
					if langs[args.match] then
						pcall(vim.treesitter.start)
						vim.bo[args.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
					end
				end,
			})
			-- Le pliage de code (fold) est désormais entièrement géré par
			-- nvim-ufo ci-dessous (foldmethod/foldexpr/foldlevel) — les deux
			-- systèmes ne peuvent pas coexister, un seul reste actif.
		end,
	},

	-- Fournit les requêtes Treesitter "textobjects" (dont @function.outer /
	-- @function.inner), consommées par mini.ai ci-dessous pour que le
	-- textobject "f" comprenne une vraie définition de fonction (signature +
	-- corps), pas juste un motif texte "nom(". Aucun réglage ni raccourci
	-- propre à ce plugin n'est activé ici : mini.ai reste seul à gérer les
	-- raccourcis, ce plugin ne sert que de fournisseur de requêtes.
	{
		"nvim-treesitter/nvim-treesitter-textobjects",
		branch = "main",
		dependencies = { "nvim-treesitter/nvim-treesitter" },
		event = "VeryLazy",
	},

	-- Rendu visuel des fichiers markdown directement dans le buffer (titres,
	-- cases à cocher, callouts, liens) — pas une prévisualisation externe,
	-- le fichier reste éditable normalement.
	{
		"MeanderingProgrammer/render-markdown.nvim",
		ft = "markdown",
		dependencies = {
			"nvim-treesitter/nvim-treesitter",
			"nvim-mini/mini.icons", -- déjà présent dans cette config, réutilisé pour les icônes
		},
		opts = {},
	},

	-- Pliage de code : aperçu du contenu plié sans avoir à l'ouvrir (zK), et
	-- rendu plus soigné que le foldtext natif basique. Remplace entièrement
	-- la gestion foldmethod/foldexpr posée dans le bloc nvim-treesitter
	-- ci-dessus (un seul système de pliage actif, pas les deux).
	{
		"kevinhwang91/nvim-ufo",
		dependencies = { "kevinhwang91/promise-async" },
		event = { "BufReadPost", "BufNewFile" },
		keys = {
			{ "zR", function() require("ufo").openAllFolds() end, desc = "Ouvrir tous les plis" },
			{ "zM", function() require("ufo").closeAllFolds() end, desc = "Fermer tous les plis" },
			{
				"zK",
				function()
					local winid = require("ufo").peekFoldedLinesUnderCursor()
					if not winid then
						vim.lsp.buf.hover()
					end
				end,
				desc = "Aperçu du pli (ou hover LSP si pas de pli)",
			},
		},
		config = function()
			vim.o.foldcolumn = "1"
			vim.o.foldlevel = 99 -- valeur haute requise par ufo, feel free to decrease if needed
			vim.o.foldlevelstart = 99 -- tout est déplié à l'ouverture d'un fichier
			vim.o.foldenable = true
			require("ufo").setup({
				provider_selector = function(bufnr, filetype, buftype)
					return { "treesitter", "indent" }
				end,
			})
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
			-- ressortent mieux avec le thème actif (italique/gras ajoutés)
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
		dependencies = { "nvim-treesitter/nvim-treesitter", "folke/tokyonight.nvim" },
		opts = function()
			-- va chercher une couleur directement dans la palette tokyonight active,
			-- avec une couleur de repli si jamais la palette n'est pas disponible
			local ok, colors = pcall(function()
				return require("tokyonight.colors").setup()
			end)
			return {
				color = (ok and colors.orange) or "#ff966c",
				highlight = { bold = true }, -- accentue la distinction visuelle des paramètres
				excluded_filetypes = { "markdown", "text", "help", "sh", "bash", "make" },
			}
		end,
	},

	-- Prévisualise les couleurs (hex, rgb, hsl) directement dans le texte —
	-- utile pour le CSS, qui fait partie de ton stack Web actif (LSP cssls +
	-- prettier déjà configurés). Fork actif : l'original (norcalli/...)
	-- n'est plus maintenu depuis longtemps.
	{
		"catgoose/nvim-colorizer.lua",
		event = { "BufReadPre", "BufNewFile" },
		opts = {
			filetypes = { "css", "html", "javascript", "typescript" },
			options = {
				parsers = {
					-- pas de couleur sur les noms anglais ("red", "blue"...),
					-- seulement les valeurs hex/rgb/hsl explicites
					names = { enable = false },
				},
			},
		},
	},

	-- Thème de couleurs (tokyonight Moon)
	{
		"folke/tokyonight.nvim",
		lazy = false, -- chargé au démarrage : c'est le thème, il doit être prêt tout de suite
		priority = 1000, -- chargé avant tous les autres plugins non-lazy
		opts = {
			style = "moon",
			transparent = true, -- laisse l'opacité du terminal (Ghostty) transparaître au lieu d'un fond opaque
			terminal_colors = true,
			styles = {
				comments = { italic = true },
			},
		},
		config = function(_, opts)
			require("tokyonight").setup(opts)
			vim.cmd.colorscheme("tokyonight-moon")
		end,
	},

	-- Curseur animé avec un effet de traînée (esthétique pure). Aucune
	-- interaction avec le reste de la config : pas de module d'animation de
	-- curseur ailleurs (mini.nvim n'inclut pas mini.animate ici), donc rien à
	-- désactiver pour éviter un doublon.
	{
		"sphamba/smear-cursor.nvim",
		event = "VeryLazy",
		opts = {
			-- "none" plutôt qu'une couleur fixe : reprend la couleur de
			-- curseur réelle du terminal, cohérente avec tokyonight-moon
			-- sans rien coder en dur ici
			cursor_color = "none",
			hide_target_hack = true,
		},
	},

	-- Icônes de fichiers (utilisé par snacks.nvim pour l'explorateur/les pickers)
	{
		"nvim-mini/mini.icons",
		version = false,
		opts = {},
	},

	-- Auto-fermeture de parenthèses/guillemets ("mini.pairs"), manipulation de
	-- guillemets/parenthèses/balises autour d'un texte ("mini.surround"),
	-- textobjects étendus af/if, etc. ("mini.ai"), et la statusline (mode,
	-- branche Git, diagnostics, type de fichier, position — "mini.statusline").
	-- Même repo que mini.icons ci-dessus (module séparé, mais même auteur/écosystème).
	{
		"nvim-mini/mini.nvim",
		version = false,
		event = "VeryLazy",
		dependencies = { "nvim-treesitter/nvim-treesitter-textobjects" },
		config = function()
			require("mini.pairs").setup()
			require("mini.surround").setup()
			require("mini.ai").setup({
				custom_textobjects = {
					-- Remplace le "f" par défaut (motif texte "nom(", pensé
					-- pour un appel de fonction) par une version Treesitter,
					-- qui comprend la vraie structure du code : signature +
					-- corps entier, pour les langages dont le parseur est
					-- installé (C, Lua, Python, HTML, CSS, JS, TS).
					f = require("mini.ai").gen_spec.treesitter({ a = "@function.outer", i = "@function.inner" }),
				},
			})
			-- mini.statusline ne règle pas laststatus lui-même (vérifié : contrairement
			-- à des alternatives comme lualine, il se contente de vérifier sa valeur) ;
			-- sans ce réglage, laststatus reste à sa valeur par défaut (2 = une
			-- statusline par split), donc plusieurs infos répétées à chaque split
			-- ouvert. 3 = une seule statusline globale pour toute la fenêtre.
			vim.opt.laststatus = 3
			require("mini.statusline").setup()
		end,
	},

	-- Saut rapide vers tout endroit visible à l'écran, motions f/F/t/T
	-- améliorées, et action à distance (ex. "yr" + label = copier sans
	-- déplacer le curseur). s/S volontairement non déclarés : même à
	-- `false`, ça crée un raccourci "vide" qui bloque le repli vers
	-- mini.surround/le S natif — le saut reste donc sur <leader><leader>.
	{
		"folke/flash.nvim",
		event = "VeryLazy",
		opts = {},
		keys = {
			{ "<leader><leader>", mode = { "n", "x", "o" }, function() require("flash").jump() end, desc = "Saut rapide (Flash)" },
			{ "r", mode = "o", function() require("flash").remote() end, desc = "Action à distance (Flash)" },
			{ "R", mode = { "o", "x" }, function() require("flash").treesitter_search() end, desc = "Recherche Treesitter (Flash)" },
			{ "<c-s>", mode = { "c" }, function() require("flash").toggle() end, desc = "Bascule Flash dans la recherche" },
		},
	},

	-- Barre d'onglets pour les buffers ouverts. Utilise mini.icons plutôt
	-- que nvim-web-devicons (mini.icons peut s'y faire passer pour lui,
	-- méthode officielle) pour éviter un deuxième fournisseur d'icônes
	-- redondant. Raccourcis réduits au strict nécessaire — pas d'utilité
	-- prouvée pour le saut par lettre ou le tri par commande pour l'instant.
	{
		"romgrk/barbar.nvim",
		event = "VeryLazy",
		dependencies = {
			"lewis6991/gitsigns.nvim", -- déjà présent : indicateurs Git sur les onglets
		},
		init = function()
			vim.g.barbar_auto_setup = false
			package.preload["nvim-web-devicons"] = function()
				require("mini.icons").mock_nvim_web_devicons()
				return package.loaded["nvim-web-devicons"]
			end
		end,
		opts = {
			-- offset propre de la ligne d'onglets quand undotree (<leader>u) est
			-- ouvert en fenêtre latérale, plutôt que de se superposer dessus
			sidebar_filetypes = {
				undotree = { text = "undotree", align = "left" },
			},
		},
		keys = {
			{ "]b", "<cmd>BufferNext<cr>", desc = "Buffer suivant" },
			{ "[b", "<cmd>BufferPrevious<cr>", desc = "Buffer précédent" },
			{ "<leader>bc", "<cmd>BufferClose<cr>", desc = "Fermer le buffer" },
		},
	},

	-- Repositionne la ligne de commande (`:`, `/`, `?`) dans une fenêtre
	-- flottante centrée. Compatible nativement avec blink.cmp, rien à
	-- régler en plus. Requiert Neovim >= 0.12 (système ui2 activé plus bas).
	-- lazy = false OBLIGATOIRE : le plugin s'initialise sur l'événement
	-- UIEnter — chargé plus tard (VeryLazy) il le raterait et ne s'activerait jamais.
	{
		"rachartier/tiny-cmdline.nvim",
		lazy = false,
		init = function()
			vim.o.cmdheight = 0
			require("vim._core.ui2").enable({})
		end,
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
			gh = {}, -- intégration GitHub (utilise le CLI "gh" en interne)
			terminal = { enabled = true }, -- terminal flottant, pour lancer make/tests sans quitter Neovim
			words = { enabled = true }, -- surlignage + navigation entre usages du mot sous le curseur
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
			{ "<leader>gp", function() Snacks.picker.gh_pr() end, desc = "Pull requests GitHub" },

			-- Terminal
			{ "<leader>tt", function() Snacks.terminal() end, desc = "Terminal flottant (bascule)" },
			{ "<leader>th", function() Snacks.terminal("htop") end, desc = "htop (moniteur système)" },

			-- Navigation entre occurrences du mot sous le curseur (surlignage
			-- déjà actif via words.enabled ci-dessus) — ]w/[w plutôt que ]]/[[
			-- (recommandation par défaut de Snacks) pour ne pas écraser le saut
			-- de section natif de Vim, que tu utilises déjà
			{ "]w", function() Snacks.words.jump(vim.v.count1) end, desc = "Occurrence suivante du mot" },
			{ "[w", function() Snacks.words.jump(-vim.v.count1) end, desc = "Occurrence précédente du mot" },

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
		dependencies = { "nvim-treesitter/nvim-treesitter" },
		-- pas de couleur à récupérer à la main : tokyonight détecte lspsaga.nvim
		-- automatiquement via lazy.nvim et applique ses propres groupes de
		-- coloration, sans configuration supplémentaire à écrire ici
		opts = {},
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
	-- sauvegarde. Pour le C dans un dossier "42", aucun formateur n'est câblé
	-- ici : la norme de ce cursus est vérifiée par `core/norminette.lua`, pas
	-- reformatée automatiquement. Ailleurs (C hors 42, Python, Web), ce sont
	-- des standards matures et déterministes (clang-format, ruff, prettier).
	{
		"stevearc/conform.nvim",
		cmd = "ConformInfo",
		keys = {
			{
				"<leader>cf",
				function()
					-- pas de lsp_fallback : si aucun formateur ne s'applique
					-- (ex. bug écarté volontairement), rien ne doit se passer
					-- plutôt que de se rabattre sur clangd et casser le scoping
					require("conform").format({ lsp_fallback = false })
				end,
				desc = "Formater le buffer",
			},
		},
		opts = {
			formatters = {
				prettier = {
					-- pointe directement vers le fichier de règles du repo, car
					-- Prettier ne supporte aucune config globale par conception
					-- (confirmé via sa doc officielle) : sans ce --config explicite,
					-- il retombe silencieusement sur ses réglages par défaut dans
					-- tout projet qui n'a pas son propre .prettierrc local
					prepend_args = { "--config", vim.fn.expand("~/dotfiles/prettier/.prettierrc") },
				},
				clang_format = {
					-- ne s'applique jamais dans un dossier "42" : la norme de ce
					-- cursus a son propre formateur dédié (voir c_formatter_42 ci-dessous)
					-- Style Microsoft : accolades sur leur propre ligne, cohérent
					-- visuellement avec la norme 42 elle-même (moins de rupture
					-- de style en passant d'un contexte à l'autre)
					prepend_args = { "-style=Microsoft" },
					condition = function(_, ctx)
						return not ctx.filename:match("/42/")
					end,
				},
				c_formatter_42 = {
					-- formateur dédié à la norme 42 (https://github.com/cacharle/c_formatter_42)
					-- installé séparément : pipx install c-formatter-42
					command = "c_formatter_42",
					stdin = true,
					condition = function(_, ctx)
						return ctx.filename:match("/42/") ~= nil
					end,
				},
			},
			formatters_by_ft = {
				-- les deux formateurs C sont mutuellement exclusifs via leur
				-- "condition" ci-dessus : un seul s'exécute réellement selon
				-- que le fichier est dans un dossier "42" ou non.
				-- stop_after_first en filet de sécurité supplémentaire : si les
				-- deux conditions passaient un jour par erreur, un seul
				-- formateur tournerait quand même (pas les deux à la suite).
				c = { "c_formatter_42", "clang_format", stop_after_first = true },
				python = { "ruff_format" },
				javascript = { "prettier" },
				typescript = { "prettier" },
				html = { "prettier" },
				css = { "prettier" },
			},
		},
		config = function(_, opts)
			-- prettier et clang-format ne sont pas des serveurs LSP :
			-- mason-lspconfig ne les installe pas automatiquement (voir plus
			-- haut, ensure_installed ne couvre que les serveurs LSP) — on s'en
			-- charge nous-mêmes ici, une seule fois. c_formatter_42 n'est pas
			-- disponible via Mason (paquet PyPI trop spécifique) : à installer
			-- manuellement avec `pipx install c-formatter-42`.
			local ok, registry = pcall(require, "mason-registry")
			if ok then
				for _, pkg_name in ipairs({ "prettier", "clang-format" }) do
					if registry.has_package(pkg_name) then
						local pkg = registry.get_package(pkg_name)
						if not pkg:is_installed() then
							pkg:install()
						end
					end
				end
			end
			require("conform").setup(opts)
		end,
	},

	-- Linting pour les fichiers hors couverture LSP — scripts shell (.sh) et C.
	-- Pas activé sur zsh/.zshrc : shellcheck ne supporte pas officiellement ce
	-- dialecte (faux positifs connus sur la syntaxe propre à zsh). cppcheck
	-- est complémentaire à clangd --clang-tidy (déjà actif via lsp/servers.lua),
	-- pas redondant : il détecte d'autres catégories de bugs (fuites mémoire,
	-- débordements, constructions suspectes) — même logique que ruff+pyright
	-- pour Python. Installation séparée requise : `brew install cppcheck`.
	{
		"mfussenegger/nvim-lint",
		event = { "BufReadPost", "BufWritePost" },
		config = function()
			require("lint").linters_by_ft = {
				sh = { "shellcheck" },
				c = { "cppcheck" },
			}
			vim.api.nvim_create_autocmd({ "BufReadPost", "BufWritePost", "InsertLeave" }, {
				callback = function()
					require("lint").try_lint()
				end,
			})
		end,
	},

	-- Repère et liste les commentaires TODO/FIXME/HACK/NOTE dans le projet —
	-- rien d'équivalent actuellement pour ce genre de suivi.
	{
		"folke/todo-comments.nvim",
		event = { "BufReadPost", "BufNewFile" },
		dependencies = { "nvim-lua/plenary.nvim" },
		opts = {},
		keys = {
			{ "<leader>st", "<cmd>TodoQuickFix<cr>", desc = "Commentaires TODO/FIXME du projet" },
		},
	},

	-- Améliore la quickfix native (utilisée par todo-comments <leader>st, les
	-- diagnostics, les recherches) : coloration syntaxique des résultats,
	-- lignes de contexte autour de chaque résultat, et surtout un buffer
	-- éditable — modifier du texte directement dans la quickfix et faire :w
	-- applique le changement dans tous les fichiers concernés d'un coup.
	{
		"stevearc/quicker.nvim",
		event = "FileType qf",
		opts = {
			-- Raccourci scopé au buffer quickfix par le plugin lui-même
			-- (mécanisme dédié, différent du "keys" de lazy.nvim ci-dessous
			-- qui sert au chargement paresseux global) : ">" affiche/masque
			-- les lignes de contexte autour de chaque résultat (façon
			-- grep -C), sans ouvrir chaque fichier un par un — désactivé par
			-- défaut même dans la config par défaut du plugin (touche
			-- laissée en exemple commenté)
			keys = {
				{ ">", function() require("quicker").toggle_expand() end, desc = "Contexte autour des résultats" },
			},
		},
		keys = {
			{ "<leader>q", function() require("quicker").toggle() end, desc = "Basculer la quickfix" },
		},
	},

	-- Visualise l'historique d'annulation sous forme d'arbre (contrairement à
	-- la liste plate de Snacks.picker.undo sur <leader>su, montre les
	-- branches créées quand on annule puis repart dans une autre direction).
	{
		"mbbill/undotree",
		cmd = "UndotreeToggle",
		keys = {
			{ "<leader>u", "<cmd>UndotreeToggle<cr>", desc = "Arbre d'annulation" },
		},
	},

    -- Passage fluide Ctrl+h/j/k/l entre splits Neovim et panneaux tmux (voir
	-- core/keymaps.lua pour les mappings, et tmux/tmux.conf pour le côté
	-- tmux du même mécanisme). no_mappings = 1 : les mappings par défaut du
	-- plugin feraient exactement la même chose que ceux déjà déclarés dans
	-- core/keymaps.lua — les garder aussi ici créerait un doublon inutile,
	-- et priverait which-key d'une description claire sur ces touches.
	{
		"christoomey/vim-tmux-navigator",
		lazy = false, -- doit être prêt dès le départ, sinon les tout premiers Ctrl+hjkl échouent
		init = function()
			vim.g.tmux_navigator_no_mappings = 1
		end,
	},

	-- Agrandit temporairement le split courant en plein écran (bascule),
	-- puis restaure exactement la disposition d'origine des splits (pas
	-- juste un partage à parts égales) — vérifié sur le code source du
	-- plugin (utilise winrestcmd() pour capturer/restaurer la disposition
	-- précise). Natif Vim (Ctrl+W _ / Ctrl+W =) peut agrandir, mais son
	-- rétablissement ne rend pas une disposition asymétrique d'origine.
	{
		"szw/vim-maximizer",
		cmd = "MaximizerToggle",
		init = function()
			vim.g.maximizer_set_default_mapping = 0 -- raccourci défini nous-mêmes ci-dessous, pas <F3>
		end,
		keys = {
			{ "<leader>mx", "<cmd>MaximizerToggle<cr>", desc = "Agrandir/restaurer le split" },
		},
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
				{ "<leader>t", group = "Terminal" },
				{ "<leader>b", group = "Buffers" },
			},
		},
	},

	-- Entraînement LeetCode directement dans Neovim : parcourir les énoncés,
	-- coder la solution dans un buffer normal, lancer les tests et soumettre,
	-- sans quitter l'éditeur. Chargé à la demande (:Leet ...) plutôt qu'au
	-- démarrage, pour ne pas alourdir l'ouverture de Neovim au quotidien.
	{
		"kawre/leetcode.nvim",
		cmd = "Leet",
		-- pas de "build" ici : le parseur Treesitter HTML est déjà installé
		-- (scope Web) ; la syntaxe ":TSUpdate html" ne fonctionne de toute
		-- façon plus avec la branche "main" de nvim-treesitter
		dependencies = {
			"nvim-lua/plenary.nvim",
			"MunifTanjim/nui.nvim",
		},
		opts = {
			lang = "c", -- langage par défaut des exercices, modifiable à tout moment ici
			picker = { provider = "snacks-picker" }, -- réutilise snacks.nvim, pas besoin de telescope
		},
	},

	-- Affiche l'activité en cours (fichier/langage) sur le profil Discord.
	-- Activable/désactivable à la volée avec la commande :CordTogglePresence,
	-- sans avoir à retoucher cette configuration.
	{
		"vyfor/cord.nvim",
		event = "VeryLazy",
		opts = {
			usercmds = true, -- active les commandes :Cord... (dont :CordTogglePresence)
		},
	},

	-- Débogueur : retiré après une longue session de diagnostic infructueuse
	-- (blocage silencieux au lancement, cause jamais identifiée avec
	-- certitude malgré vérification de l'adaptateur, des permissions macOS
	-- et des logs) — à reconsidérer plus tard si besoin, pas maintenant.
}