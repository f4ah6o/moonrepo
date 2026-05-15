# n8n Workflow Features - Quick Reference for MoonBit

## Files Analyzed

| File | Size | Purpose |
|------|------|---------|
| `packages/workflow/src/Expression.ts` | 595 lines | Expression evaluation & sandboxing |
| `packages/workflow/src/workflow-data-proxy.ts` | 1586 lines | Workflow data access & item iteration |
| `packages/workflow/src/node-helpers.ts` | 1980 lines | Node parameter resolution & validation |
| `packages/workflow/src/workflow.ts` | 925 lines | Workflow container & graph mgmt |
| `packages/workflow/src/interfaces.ts` | 3527 lines | All type definitions |
| `packages/core/src/execution-engine/workflow-execute.ts` | 86,225 lines | Execution orchestration |

---

## Top 10 Most Valuable Features

### Tier 1: MUST HAVE (Execution Core)
1. **Workflow & Node Graph** - Container, nodes, connections
2. **Execution Data Model** - IRun, ITaskData, INodeExecutionData types
3. **Basic Execution Loop** - Sequential node execution with data flow
4. **Parameter Resolution** - Extract parameters from node definitions
5. **Expression Evaluation** - Dynamic `=expression` in node parameters

### Tier 2: IMPORTANT (Common Use Cases)
6. **Error Handling** - Per-node error capture and handling
7. **Execution Context** - Access to flow/node context during execution
8. **Data Proxy Access** - Safe access to previous node outputs
9. **Retry Logic** - Automatic retry on node failure
10. **Waiting States** - Support for async/webhook nodes

---

## Feature Implementation Order (Recommended)

```
Phase 1: Execution Foundation (2-3 months)
  └─ Data Types → Basic Workflow → Execution Engine
  
Phase 2: Practical Workflows (1-2 months)
  └─ Expression Eval → Parameter Resolution → Error Handling
  
Phase 3: Advanced Features (2-3 months)
  └─ Retry → Waiting States → Hooks → Pin Data
  
Phase 4: Enterprise Features (3+ months)
  └─ Sub-workflows → Partial Execution → Paired Items
```

---

## Code Examples

### 1. Core Execution Loop
```typescript
// Simplified execution logic
class WorkflowExecute {
  async run(workflow, startNode) {
    let currentNode = startNode
    
    while (currentNode) {
      const result = await this.executeNode(currentNode)
      
      // Store result
      this.runData[currentNode.name] = result
      
      // Get next node(s)
      currentNode = workflow.getNextNode(currentNode)
    }
    
    return this.runData
  }
}
```

### 2. Expression Evaluation
```typescript
// In node parameters
"message": "=Hello, " + $node['HttpRequest'].json.name"
// Becomes evaluated to actual value during execution

// Sandboxed evaluation
const value = new Expression(timezone).resolveSimpleParameterValue(
  parameterValue,
  workflowData,
  false
)
```

### 3. Data Access (Workflow Data Proxy)
```typescript
// In node expressions or code
$node['PreviousNode'].json.property     // Get previous node output
$json.field                              // Current item JSON
$item(index)                             // Get item at index
$getPairedItem(0)                        // Get lineage tracking
```

---

## Security Considerations

### Expression Sandboxing (Critical)
- Block: `eval`, `require`, `Function`, `Proxy`, `Reflect`
- Block: `process`, `Buffer`, `__dirname`, `__filename`
- Block: `fetch`, `XMLHttpRequest`, `setTimeout`
- Block: `Object.defineProperty`, `Object.setPrototypeOf`
- Allow: Math, String, Array, JSON, Date, DateTime (Luxon)

### Two Evaluation Engines
- **Current**: Standard JavaScript evaluation with sandboxing
- **VM**: Optional isolated VM with timeout & memory limits

---

## Key Performance Considerations

1. **Lazy Evaluation** - Don't load all execution data upfront
2. **Streaming Items** - Process large item arrays in batches
3. **Expression Caching** - Cache compiled expressions
4. **Async Coordination** - Use efficient awaiting/promises
5. **Memory Management** - Cleanup after execution, manage binary data

---

## Testing Strategy

### Unit Tests
- Node parameter resolution
- Expression evaluation (valid & invalid)
- Data proxy access patterns
- Error handling paths

### Integration Tests
- Simple 2-3 node workflows
- With expressions in parameters
- With different node types
- With errors and retries

### Performance Tests
- Large item arrays (1000+ items)
- Deep node trees (20+ nodes)
- Complex expressions
- Binary data handling

---

## Implementation Notes

### TypeScript → MoonBit Mapping
```
IDataObject          → Map<String, Value>
INodeExecutionData[] → Array of Item records
Promise<T>           → Effect system / Continuation
unknown / any        → Record type / Variant
IConnectionType enum → String or Variant
```

### Critical Interfaces to Implement First
```
IRun {
  data: IRunExecutionData
  mode: "manual" | "trigger" | ...
  status: "success" | "failed" | "running"
  startedAt: Date
  stoppedAt: Date
}

ITaskData {
  node: INode
  data: ITaskDataConnections
  error?: ExecutionError
}

INodeExecutionData {
  json: IDataObject
  pairedItem: number
  binary?: Map<string, IBinaryData>
}
```

---

## Dependencies & Alternatives

### Required Libraries
- DateTime handling: Use Luxon equivalent in MoonBit
- Expression sandboxing: Consider existing expression libraries
- Binary data: Use bytes/buffers in MoonBit

### Optional
- Webhook support: Web framework (same as host)
- Task scheduling: Async/concurrency library
- Observability: Logging & telemetry system

---

## Risk Areas & Mitigation

| Risk | Impact | Mitigation |
|------|--------|-----------|
| Expression sandboxing bypass | Security | Whitelist approach, regular audits |
| Complex async state | Execution bugs | Immutable state, transaction-like steps |
| Memory with large data | Performance | Streaming, cleanup, garbage collection |
| Type flexibility loss | Dev experience | Variants, records, careful API design |
| Partial execution complexity | Feature delay | Phase this in Phase 4 |

---

## Estimated LOC for Core Implementation

```
Data Types:           ~500 lines
Workflow Class:       ~1000 lines
Execution Engine:     ~5000-7000 lines
Node Helpers:         ~2000 lines
Expression Eval:      ~1500-2000 lines (or use library)
Data Proxy:           ~1500-2000 lines
Error Handling:       ~500 lines
Execution Context:    ~300 lines
Basic Hooks:          ~300 lines
─────────────────────────────
Total Core:           ~13,500-16,000 lines
```

---

## References

- n8n GitHub: https://github.com/n8n-io/n8n
- Workflow Package: `packages/workflow/`
- Core Package: `packages/core/`
- Expression Runtime: `@n8n/expression-runtime`

