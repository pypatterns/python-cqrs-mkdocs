# Mermaid diagrams

- **Back to Testing Overview**

  Return to the Testing overview page with all topics.

  [Back to Overview](https://mkdocs.python-cqrs.dev/latest/testing/index.md)

This is not run through `test_harness`. `CoRMermaid` generates diagrams for Chain of Responsibility handler chains: a sequence diagram of the execution flow, and a class diagram of the handlers, the request, and the response. `SagaMermaid` generates diagrams for saga instances: a sequence diagram of execution, failure, and compensation, and a class diagram of the saga, its steps, and its context. Drawing a diagram takes no part in `send`, so `invocations` stays empty.

See [Mermaid diagrams](https://mkdocs.python-cqrs.dev/latest/mermaid/index.md).

```python
def test_cor_sequence_diagram_names_each_step() -> None:
    diagram = cqrs.CoRMermaid([CardHandler, CashHandler])

    sequence = diagram.sequence()

    assert "CardHandler" in sequence
    assert "CashHandler" in sequence
```

Library example: [`examples/testing/test_outside_harness.py`](https://github.com/vadikko2/python-cqrs/blob/master/examples/testing/test_outside_harness.py).
