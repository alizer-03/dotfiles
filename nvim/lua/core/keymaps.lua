-- U (par défaut : annuler toute la ligne, quasi jamais utilisé) redéfini en
-- redo, raccourci plus rapide que Ctrl+R
vim.keymap.set("n", "U", "<C-r>", { desc = "Redo" })

-- Navigation entre splits Neovim ET panneaux tmux avec les mêmes touches
-- (vim-tmux-navigator, dépendance déclarée dans plugins/init.lua) : passe au
-- split voisin s'il y en a un, sinon délègue au panneau tmux correspondant
-- (voir tmux/tmux.conf, côté tmux du même mécanisme) — un seul geste pour
-- traverser toute la grille, qu'elle soit faite de splits ou de panneaux.
vim.keymap.set("n", "<C-h>", "<cmd>TmuxNavigateLeft<cr>", { desc = "Split/panneau de gauche" })
vim.keymap.set("n", "<C-j>", "<cmd>TmuxNavigateDown<cr>", { desc = "Split/panneau du dessous" })
vim.keymap.set("n", "<C-k>", "<cmd>TmuxNavigateUp<cr>", { desc = "Split/panneau du dessus" })
vim.keymap.set("n", "<C-l>", "<cmd>TmuxNavigateRight<cr>", { desc = "Split/panneau de droite" })

-- Retire les raccourcis LSP natifs (Neovim 0.11+) qui font doublon exact
-- avec Lspsaga ci-dessous (rename/code_action/references/outline) — un seul
-- réflexe à retenir pour ces 4 actions plutôt que deux chemins équivalents,
-- sans perte de contenu ni de confort (nombre de touches identique).
-- gri (implementation) et grt (type_definition) restent natifs :
-- - grt n'a aucun équivalent Lspsaga dans cette config
-- - gri chevauche en partie <leader>lf (Lspsaga finder inclut déjà les
--   implémentations par défaut), mais gardé volontairement pour le saut
--   direct quand il n'y en a qu'une seule — plus rapide que d'ouvrir une
--   liste à chaque fois
vim.api.nvim_create_autocmd("VimEnter", {
	once = true,
	callback = function()
		for _, key in ipairs({ "grn", "gra", "grr", "gO" }) do
			pcall(vim.keymap.del, "n", key)
		end
		pcall(vim.keymap.del, "x", "gra") -- gra existe aussi en mode visuel
	end,
})

-- Raccourcis liés au LSP (ici Lspsaga), définis uniquement sur les buffers où
-- un client LSP est réellement attaché — pas de raccourcis fantômes sur un
-- fichier texte quelconque où il n'y aurait rien à faire.
vim.api.nvim_create_autocmd("LspAttach", {
	group = vim.api.nvim_create_augroup("lsp-keymaps", { clear = true }),
	callback = function(args)
		local bufnr = args.buf

		-- Neovim 0.11+ règle automatiquement 'formatexpr' sur le formatage LSP
		-- (clangd pour le C) dès qu'un serveur qui le supporte s'attache — ce
		-- qui fait que gq/gqq appellerait clangd directement, en contournant
		-- entièrement conform.nvim et son scoping c_formatter_42 vs
		-- clang_format (confirmé : gqq a réindenté une ligne du dossier 42
		-- avec le style clangd, pas celui attendu). On vide 'formatexpr' pour
		-- que gq retombe sur le comportement natif de Vim (retour à la ligne
		-- simple, sans appel LSP) ; le formatage reste uniquement accessible
		-- via <leader>cf (conform.nvim), qui applique le bon formateur selon
		-- le dossier.
		vim.bo[bufnr].formatexpr = ""

		-- petit raccourci local pour éviter de répéter { buffer = bufnr, ... } à chaque ligne
		local function map(mode, lhs, rhs, desc)
			vim.keymap.set(mode, lhs, rhs, { buffer = bufnr, silent = true, desc = desc })
		end

		map("n", "<leader>lo", "<cmd>Lspsaga outline<cr>", "Arbre des symboles")
		map("n", "<leader>lf", "<cmd>Lspsaga finder<cr>", "Références et définitions")
		map("n", "<leader>lc", "<cmd>Lspsaga code_action<cr>", "Actions de code")
		map("n", "<leader>lr", "<cmd>Lspsaga rename<cr>", "Renommer")

		-- Call hierarchy : qui appelle cette fonction, et qu'est-ce qu'elle appelle
		map("n", "<leader>li", "<cmd>Lspsaga incoming_calls<cr>", "Appels entrants")
		map("n", "<leader>lO", "<cmd>Lspsaga outgoing_calls<cr>", "Appels sortants")
	end,
})