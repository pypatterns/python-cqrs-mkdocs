---
title: Mermaid diagrams
description: CoRMermaid and SagaMermaid draw sequence and class diagrams. They take no part in send.
---

# Mermaid diagrams

<div class="grid cards" markdown>

-   :material-home: **Back to Testing Overview**

    Return to the Testing overview page with all topics.

    [:octicons-arrow-left-24: Back to Overview](index.md)

</div>

This is not run through `test_harness`. `CoRMermaid` generates diagrams for Chain of Responsibility handler chains: a sequence diagram of the execution flow, and a class diagram of the handlers, the request, and the response. `SagaMermaid` generates diagrams for saga instances: a sequence diagram of execution, failure, and compensation, and a class diagram of the saga, its steps, and its context. Drawing a diagram takes no part in `send`, so `invocations` stays empty.

See [Mermaid diagrams](../mermaid/index.md).

```python
diagram = cqrs.CoRMermaid([CardHandler, CashHandler]).sequence()
assert "CardHandler" in diagram
```
