import inspect
import textwrap
import functools

from typing import Callable

from autogoal.search import PESearch
from autogoal.grammar import generate_cfg


def _make_params_func(fn: Callable):
    signature = inspect.signature(fn)

    func_name = f"{fn.__name__}_params"
    args_names = signature.parameters.keys()
    args_line = ",\n            ".join(f"{k}={k}" for k in args_names)

    func_code = textwrap.dedent(
        f"""
    def {func_name}{signature}:
        return dict(
            {args_line}
        )
    """
    )

    print(func_code)
    locals_dict = {}
    exec(func_code, fn.__globals__, locals_dict)
    return locals_dict[func_name]


def optimize(fn, search_strategy=None, iterations=None, **kwargs):
    if search_strategy is None:
        search_strategy = PESearch

    params_func = _make_params_func(fn)

    @functools.wraps(fn)
    def eval_func(kwargs):
        return fn(**kwargs)

    grammar = generate_cfg(params_func)

    search = search_strategy(grammar, eval_func, **kwargs)
    best, best_fn = search.run(iterations)

    return best, best_fn
