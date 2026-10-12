"""Stdin-only syntax evidence, never execution or proof of assertion correctness. Accept straight-line imports/assignments/assertions, literal nonempty case loops, and undecorated zero-argument test functions called directly or in a main guard. Reject other control flow, short-circuit expressions, unknown calls and rebinding callables. Bounds deliberately reject complex files instead of constructing a CFG."""
import ast
import json
import sys
def recognize(source):
    tree = ast.parse(source)
    if len(source) > 100_000 or sum(1 for _ in ast.walk(tree)) > 10_000:
        raise ValueError()
    found, remaining = False, 10_000
    def expression(node, names):
        if isinstance(node, ast.Constant):
            return False
        if isinstance(node, ast.Name) and isinstance(names.get(node.id), bool):
            return names[node.id]
        if isinstance(node, (ast.Tuple, ast.List)):
            return any([expression(item, names) for item in node.elts])
        if isinstance(node, ast.JoinedStr):
            if any(isinstance(item, ast.FormattedValue) and item.format_spec is not None for item in node.values):
                raise ValueError()
            return any([expression(item.value, names) if isinstance(item, ast.FormattedValue) else expression(item, names) for item in node.values])
        if isinstance(node, ast.Compare) and len(node.ops) == 1:
            return any([expression(item, names) for item in [node.left, *node.comparators]])
        if isinstance(node, ast.Call) and isinstance(node.func, ast.Name) and names.get(node.func.id) == 'label':
            if len(node.args) != 1 or node.keywords:
                raise ValueError()
            expression(node.args[0], names)
            return True
        if isinstance(node, ast.Call) and isinstance(node.func, ast.Name) and node.func.id == 'len' and 'len' not in names and len(node.args) == 1 and not node.keywords:
            return expression(node.args[0], names)
        raise ValueError()
    def bind(target, value, names, literals):
        if isinstance(target, ast.Name) and (target.id not in names or isinstance(names[target.id], bool)):
            names[target.id] = value
            literals.pop(target.id, None)
        elif isinstance(target, (ast.Tuple, ast.List)) and value is False and all(isinstance(item, ast.Name) for item in target.elts):
            for item in target.elts:
                bind(item, False, names, literals)
        else:
            raise ValueError()
    def block(body, names, literals, depth=0):
        nonlocal found, remaining
        if depth > 12:
            raise ValueError()
        for node in body:
            remaining -= 1
            if remaining < 0:
                raise ValueError()
            if isinstance(node, ast.ImportFrom) and node.module == 'label' and node.level == 0 and all(a.name == 'label' for a in node.names):
                for alias in node.names:
                    key = alias.asname or alias.name
                    if key in names:
                        raise ValueError()
                    names[key] = 'label'
            elif isinstance(node, ast.Assign) and len(node.targets) == 1 and isinstance(node.targets[0], ast.Name):
                bind(node.targets[0], expression(node.value, names), names, literals)
                if isinstance(node.targets[0], ast.Name) and isinstance(node.value, (ast.Tuple, ast.List)) and all(isinstance(n, (ast.Constant, ast.Tuple, ast.List, ast.Load)) for n in ast.walk(node.value)):
                    literals[node.targets[0].id] = node.value
            elif isinstance(node, ast.Assert):
                found = expression(node.test, names) or found
                if node.msg:
                    expression(node.msg, names)
            elif isinstance(node, ast.FunctionDef) and not node.decorator_list and not node.returns and not node.args.args and not node.args.posonlyargs and not node.args.kwonlyargs and not node.args.vararg and not node.args.kwarg:
                if node.name in names:
                    raise ValueError()
                names[node.name] = node
            elif isinstance(node, ast.If) and ast.dump(node.test) == ast.dump(ast.parse('__name__ == "__main__"', mode='eval').body) and '__name__' not in names:
                block(node.body, names, literals, depth + 1)
            elif isinstance(node, ast.For) and not node.orelse:
                cases = literals.get(node.iter.id) if isinstance(node.iter, ast.Name) else node.iter
                if not isinstance(cases, (ast.Tuple, ast.List)) or not cases.elts or not all(isinstance(n, (ast.Constant, ast.Tuple, ast.List, ast.Load)) for n in ast.walk(cases)):
                    raise ValueError()
                if isinstance(node.target, (ast.Tuple, ast.List)) and not all(isinstance(item, (ast.Tuple, ast.List)) and len(item.elts) == len(node.target.elts) for item in cases.elts):
                    raise ValueError()
                bind(node.target, False, names, literals)
                block(node.body, names, literals, depth + 1)
            elif isinstance(node, ast.Expr) and isinstance(node.value, ast.Call) and isinstance(node.value.func, ast.Name):
                call = node.value
                function = names.get(call.func.id)
                if isinstance(function, ast.FunctionDef) and not call.args and not call.keywords:
                    local = names.copy()
                    local_literals = literals.copy()
                    for item in ast.walk(function):
                        if isinstance(item, ast.Name) and isinstance(item.ctx, ast.Store):
                            local.pop(item.id, None)
                            local_literals.pop(item.id, None)
                    block(function.body, local, local_literals, depth + 1)
                elif call.func.id == 'print' and 'print' not in names and not call.keywords:
                    for arg in call.args:
                        expression(arg, names)
                else:
                    raise ValueError()
            elif not isinstance(node, ast.Pass) and not (isinstance(node, ast.Expr) and isinstance(node.value, ast.Constant)):
                raise ValueError()
    block(tree.body, {}, {})
    return found
try:
    passed = recognize(sys.stdin.read(100_001))
except (SyntaxError, ValueError, RecursionError, TypeError):
    passed = False
print(json.dumps({'passed': passed}))
