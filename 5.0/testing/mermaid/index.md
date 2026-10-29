# Mermaid diagrams

- **Back to Testing Overview**

  Return to the Testing overview page with all topics.

  [Back to Overview](https://mkdocs.python-cqrs.dev/latest/testing/index.md)

This is not run through `test_harness`. `CoRMermaid` generates diagrams for Chain of Responsibility handler chains: a sequence diagram of the execution flow, and a class diagram of the handlers, the request, and the response. `SagaMermaid` generates diagrams for saga instances: a sequence diagram of execution, failure, and compensation, and a class diagram of the saga, its steps, and its context. Drawing a diagram takes no part in `send`, so `invocations` stays empty.

See [Mermaid diagrams](https://mkdocs.python-cqrs.dev/latest/mermaid/index.md).

```python
diagram = cqrs.CoRMermaid([CardHandler, CashHandler]).sequence()
assert "CardHandler" in diagram
```
