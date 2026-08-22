-- Snippets LuaSnip pour les conventions 42 : tabulations systématiques,
-- prototypes avec type de retour et nom séparés par une tabulation, etc.
-- Chargé automatiquement depuis lua/plugins/init.lua.
-- Note : les "\t" entre guillemets plus bas sont de vraies tabulations,
-- requises à la fois par la norme C visée et par les recettes Makefile.

local ls = require("luasnip")
local s = ls.snippet
local i = ls.insert_node -- un point où le curseur s'arrête pour que l'utilisateur tape quelque chose
local t = ls.text_node -- texte fixe, inséré tel quel
local f = ls.function_node -- texte calculé dynamiquement par une fonction Lua

-- Construit un nom de macro de garde d'en-tête à partir du nom du fichier
-- courant, ex : ft_printf.h -> FT_PRINTF_H
local function guard()
	local name = vim.fn.expand("%:t")
	if name == "" then
		name = "HEADER_H" -- nom de repli si le buffer n'est pas encore un fichier nommé
	end
	return (name:gsub("[%.%-]", "_"):upper())
end

local M = {}

M.c = {
	-- "main" : squelette d'une fonction main() sans arguments
	s("main", {
		t({ "int\tmain(void)", "{", "\t" }),
		i(1),
		t({ "", "\treturn (0);", "}" }),
	}),

	-- "mainargs" : squelette d'une fonction main() avec argc/argv
	s("mainargs", {
		t({ "int\tmain(int argc, char **argv)", "{", "\t" }),
		i(1),
		t({ "", "\treturn (0);", "}" }),
	}),

	-- "ftfn" : squelette générique de fonction, avec type de retour, nom
	-- (préfixé "ft_") et paramètres tous modifiables
	s("ftfn", {
		i(1, "int"),
		t("\tft_"),
		i(2, "name"),
		t("("),
		i(3, "void"),
		t({ ")", "{", "\t" }),
		i(4),
		t({ "", "}" }),
	}),

	-- "guard" : macro de garde d'en-tête (#ifndef/#define/#endif), avec le
	-- nom déduit automatiquement du fichier courant via guard()
	s("guard", {
		t("#ifndef "),
		f(guard),
		t({ "", "# define " }),
		f(guard),
		t({ "", "", "" }),
		i(1),
		t({ "", "", "#endif" }),
	}),
}

M.make = {
	-- "makefile" : Makefile de base pour compiler un exécutable C, avec
	-- les cibles standards (all, clean, fclean, re)
	s("makefile", {
		t("NAME\t= "),
		i(1, "a.out"),
		t({ "", "", "CC\t\t= cc", "CFLAGS\t= -Wall -Wextra -Werror", "", "SRCS\t= " }),
		i(2, "main.c"),
		t({
			"",
			"OBJS\t= $(SRCS:.c=.o)",
			"",
			"all: $(NAME)",
			"",
			"$(NAME): $(OBJS)",
			"\t$(CC) $(CFLAGS) $(OBJS) -o $(NAME)",
			"",
			"%.o: %.c",
			"\t$(CC) $(CFLAGS) -c $< -o $@",
			"",
			"clean:",
			"\trm -f $(OBJS)",
			"",
			"fclean: clean",
			"\trm -f $(NAME)",
			"",
			"re: fclean all",
			"",
			".PHONY: all clean fclean re",
			"",
		}),
	}),
}

M.python = {
	-- "main" : garde d'entrée standard d'un script Python, pour que le
	-- code sous ce bloc ne s'exécute que si le fichier est lancé
	-- directement (pas quand il est importé depuis un autre fichier)
	s("main", {
		t({ 'if __name__ == "__main__":', "    " }),
		i(1),
	}),
}

M.html = {
	-- "html5" : squelette de base d'un document HTML5 complet
	s("html5", {
		t({
			"<!doctype html>",
			'<html lang="en">',
			"<head>",
			'\t<meta charset="UTF-8">',
			"\t<title>",
		}),
		i(1, "Titre"),
		t({
			"</title>",
			"</head>",
			"<body>",
			"\t",
		}),
		i(2),
		t({
			"",
			"</body>",
			"</html>",
		}),
	}),
}

return M