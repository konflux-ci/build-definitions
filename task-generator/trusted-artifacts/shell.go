package main

import (
	"regexp"
	"slices"
	"sort"
	"strings"

	"mvdan.cc/sh/v3/fileutil"
	"mvdan.cc/sh/v3/syntax"
)

var (
	parser  = syntax.NewParser(syntax.KeepComments(true))
	printer = syntax.NewPrinter(syntax.KeepPadding(true), syntax.Indent(2))
)

func removeEnvUse(f *syntax.File, name string) []*syntax.Stmt {
	modified := make([]*syntax.Stmt, 0, len(f.Stmts))
	syntax.Walk(f, func(node syntax.Node) bool {
		if p, ok := node.(*syntax.ParamExp); ok {
			// parameter expansion, e.g. ${name}
			if p.Param.Value == name {
				// remove every line starting from the line where the ${name} was used
				start := p.Param.Pos().Line()

				var end uint = 0
				for _, s := range f.Stmts {
					line := s.Pos().Line()
					if line == start {
						if ifstmt, ok := s.Cmd.(*syntax.IfClause); ok {
							// if the if statement is at the start line, remove
							// the lines till the corresponding `fi` statement
							end = ifstmt.FiPos.Line()
						}
						if assign, ok := s.Cmd.(*syntax.CallExpr); ok {
							// remove the whole assignment
							end = assign.End().Line()
						}
					}

					if line < start || (line > end || end == 0) {
						// add only the lines that are not in the start-end segment
						modified = append(modified, s)
					}
				}
			}
		}

		return true
	})

	if len(modified) == 0 {
		// if the environment variable is not found, the modified slice will be empty
		return f.Stmts
	}

	return modified
}

func removeUnusedFunctions(f *syntax.File) []*syntax.Stmt {
	used := make([]string, 0, 10) // includes used functions and other calls (echo, printf...)
	syntax.Walk(f, func(node syntax.Node) bool {
		if c, ok := node.(*syntax.CallExpr); ok && len(c.Args) > 0 {
			// first argument of a call statement is the name
			used = append(used, c.Args[0].Lit())
		}

		return true
	})

	sort.Strings(used)

	forRemoval := make([]struct{ start, end uint }, 0, 10)
	syntax.Walk(f, func(node syntax.Node) bool {
		if fn, ok := node.(*syntax.FuncDecl); ok {
			if _, found := slices.BinarySearch(used, fn.Name.Value); !found {
				// we found a function declared and unused
				forRemoval = append(forRemoval, struct{ start, end uint }{fn.Pos().Line(), fn.End().Line()})
			}
		}
		return true
	})

	modified := make([]*syntax.Stmt, 0, len(f.Stmts))
	for _, s := range f.Stmts {
		line := s.Position.Line()
		remove := false
		for _, r := range forRemoval {
			if remove = line >= r.start && line <= r.end; remove {
				// found lines comprising a unused function declaration
				break
			}
		}

		if !remove {
			modified = append(modified, s)
		}
	}

	return modified
}

func replaceLiterals(f *syntax.File, rx map[*regexp.Regexp]string) []*syntax.Stmt {
	syntax.Walk(f, func(n syntax.Node) bool {
		if l, ok := n.(*syntax.Lit); ok {
			l.Value = applyRegexReplacements(l.Value, rx)
		}
		if s, ok := n.(*syntax.Stmt); ok {
			for i := range s.Comments {
				s.Comments[i].Text = applyRegexReplacements(s.Comments[i].Text, rx)
			}
		}
		return true
	})

	return f.Stmts
}

func isShell(script string) bool {
	if script == "" {
		return false
	}

	// fileutil.Shebang returns "" if the shebang is not shell
	if shebang := fileutil.Shebang([]byte(script)); shebang != "" {
		return true
	}

	// folk don't add shebangs so missing one defaults to shell
	if !strings.HasPrefix(script, "#!") {
		return true
	}

	return false
}
