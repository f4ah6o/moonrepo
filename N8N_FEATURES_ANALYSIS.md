# n8n TypeScript Workflow Features - Analysis for MoonBit Porting

## Executive Summary
This analysis identifies 20+ valuable workflow execution features from n8n's TypeScript codebase that could enhance MoonBit's workflow capabilities. Features are categorized by complexity and criticality.

---

## CORE FEATURES (Essential for Basic Workflows)

### 1. **Expression Evaluation System** 
**File**: `packages/workflow/src/Expression.ts` (595 lines)

**What it does**:
- Evaluates dynamic expressions in node parameters (prefixed with `=`)
- Supports dual evaluation engines: "current" (standard) and "vm" (isolated VM with timeout/memory limits)
- Implements comprehensive security sandboxing to prevent RCE attacks
- Blocks dangerous JavaScript APIs (eval, require, Function, Proxy, Reflect, etc.)
- Supports DateTime, Duration, Interval from Luxon library
- Features expression extension system for custom functions

**Key Components**:
```typescript
class Expression {
  private static expressionEngine: 'current' | 'vm'
  
  resolveSimpleParameterValue(
    parameterValue: NodeParameterValue,
    data: IWorkflowDataProxyData,
    returnObjectAsString?: boolean
  )
  
  static initializeVmEvaluator()  // Optional VM sandbox
  convertObjectValueToString(value)
}
```

**Complexity to Port**: **HIGH** (200-300 hours)
- Requires implementing expression parser/evaluator
- Security sandboxing is critical and complex
- Consider using existing expression evaluator library

**Criticality**: **CORE** - Used in virtually every workflow

---

### 2. **Workflow Data Proxy**
**File**: `packages/workflow/src/workflow-data-proxy.ts` (1586 lines)

**What it does**:
- Provides safe access to workflow data during node execution
- Manages item iteration and array access
- Handles paired item tracking (maintains data lineage across nodes)
- Supports shorthand syntax for accessing previous node outputs
- Implements lazy loading of execution data
- Manages binary data access based on workflow settings

**Key Components**:
```typescript
export class WorkflowDataProxy {
  constructor(
    workflow: Workflow,
    runExecutionData: IRunExecutionData,
    runIndex: number,
    itemIndex: number,
    activeNodeName: string,
    connectionInputData: INodeExecutionData[],
    // ... additional config
  )
  
  // Methods for accessing node data
  getNodeExecutionOrPinnedData()
  getNodeExecutionData()
  resolveParameterValue()
}
```

**Complexity to Port**: **HIGH** (150-200 hours)
- Complex proxy object with lazy evaluation
- Paired item tracking adds significant logic
- Performance-critical component

**Criticality**: **CORE** - Essential for node data access

---

### 3. **Node Helpers Utilities**
**File**: `packages/workflow/src/node-helpers.ts` (1980 lines)

**What it does**:
- Resolves node parameters from node property definitions
- Validates node configurations against schema
- Extracts context data (flow/node context)
- Handles conditional parameter display
- Manages webhook paths and URLs
- Validates parameter issues (missing required, invalid type, etc.)

**Key Functions**:
```typescript
export function getNodeParameters(
  nodePropertiesArray: INodeProperties[],
  nodeValues: INodeParameters | null,
  returnDefaults: boolean,
  returnNoneDisplayed: boolean,
  // ...options
): INodeParameters | null

export function getContext(
  runExecutionData: IRunExecutionData,
  type: 'flow' | 'node',
  node?: INode
): IContextObject  // Returns flow or node context

export function getNodeParametersIssues(
  nodePropertiesArray: INodeProperties[],
  node: INode,
  nodeTypeDescription: INodeTypeDescription,
  pinDataNodeNames?: string[]
): INodeIssues | null  // Validation results
```

**Complexity to Port**: **MEDIUM** (100-150 hours)
- Most is validation and helper logic
- Parameter dependency resolution is complex

**Criticality**: **CORE** - Required for parameter resolution

---

### 4. **Basic Workflow Class**
**File**: `packages/workflow/src/workflow.ts` (925 lines, excerpt)

**What it does**:
- Main workflow container managing nodes and connections
- Provides graph traversal (get parent/child nodes)
- Stores static data and pin data
- Manages workflow settings (timezone, binary mode, etc.)
- Integrates expression evaluator

**Key Properties**:
```typescript
export class Workflow {
  id: string
  name: string | undefined
  nodes: INodes = {}
  connections: IConnections = {}
  nodeTypes: INodeTypes
  expression: WorkflowExpression
  active: boolean
  settings: IWorkflowSettings
  staticData: IDataObject
  pinData?: IPinData
  
  // Graph methods
  getStartNode()
  getNode(nodeName: string)
  getParentNodes(nodeName: string, connectionType?: NodeConnectionType)
  getChildNodes(nodeName: string, connectionType?: NodeConnectionType)
}
```

**Complexity to Port**: **LOW-MEDIUM** (50-100 hours)
- Straightforward data container
- Graph algorithms are standard implementations

**Criticality**: **CORE** - Foundation of workflow system

---

## EXECUTION ENGINE FEATURES

### 5. **Workflow Execution Engine**
**File**: `packages/core/src/execution-engine/workflow-execute.ts` (86,225 lines - large!)

**What it does**:
- Main execution orchestrator for running workflows
- Manages execution lifecycle and state
- Handles error recovery and retry logic
- Coordinates with various hook systems
- Supports multiple execution modes

**Key Components**:
```typescript
export class WorkflowExecute {
  private status: ExecutionStatus = 'new'
  private readonly abortController = new AbortController()
  timedOut: boolean = false
  
  run({
    workflow,
    startNode,
    destinationNode,
    pinData,
    triggerToStartFrom,
    additionalRunFilterNodes
  }): PCancelable<IRun>  // Cancelable promise for execution
  
  private async executeNode(
    workflow: Workflow,
    node: INode,
    nodeType: INodeType,
    // ... many parameters
  ): Promise<IRunNodeResponse | EngineRequest>
}
```

**Complexity to Port**: **VERY HIGH** (400-600 hours)
- Massive file with deep complexity
- Multiple execution paths (normal, poll, trigger, webhook)
- Partial execution support
- Agent/tool node execution
- Requires deep understanding of execution state

**Criticality**: **CORE** - The execution engine itself

---

### 6. **Retry Logic**
**Found in**: `workflow-execute.ts` lines ~1600+

**What it does**:
- Retries failed node executions with exponential backoff
- Configurable max tries (2-5 attempts)
- Configurable wait time between retries
- Re-queues node execution on stack for retry

**Code Pattern**:
```typescript
let maxTries = 1;
if (executionData.node.retryOnFail === true) {
  maxTries = Math.min(5, Math.max(2, executionData.node.maxTries || 3));
}

let waitBetweenTries = 0;
if (executionData.node.retryOnFail === true) {
  // Configurable wait time
  waitBetweenTries = (executionData.node.waitBetweenTries || 0) * 1000;
}

// On failure: re-queue the node
this.runExecutionData.executionData!.nodeExecutionStack.unshift(executionData);
```

**Complexity to Port**: **LOW** (20-30 hours)
- Straightforward retry mechanism
- Basic state management

**Criticality**: **ADVANCED** - Nice-to-have for robustness

---

### 7. **Error Handling Per Node**
**What it does**:
- Catches errors at node execution level
- Passes execution error objects through pipeline
- Supports error handling in flow context
- Creates error traces for debugging

**Interfaces**:
```typescript
export type ExecutionError =
  | ExpressionError
  | WorkflowActivationError
  | WorkflowOperationError
  | ExecutionCancelledError
  | NodeOperationError
  | NodeApiError

// Stored in execution data
interface ITaskData extends ITaskStartedData {
  error?: ExecutionError
  metadata?: ITaskMetadata
}
```

**Complexity to Port**: **MEDIUM** (60-100 hours)
- Requires structured error types
- Error propagation through execution stack

**Criticality**: **CORE** - Essential for reliability

---

## ADVANCED FEATURES

### 8. **Pin Data System**
**What it does**:
- Allows pinning node output data for manual testing
- Overrides actual execution with pinned test data
- Used for workflow debugging/development
- Supports partial workflow execution with pinned intermediate results

**Type Definition**:
```typescript
export interface IPinData {
  [nodeName: string]: INodeExecutionData[]
}

// Used in workflow execution
interface RunWorkflowOptions {
  pinData?: IPinData
}
```

**Complexity to Port**: **LOW** (30-50 hours)
- Simple data override mechanism
- Basic conditional logic in execution path

**Criticality**: **ADVANCED** - Testing/debugging feature

---

### 9. **Execution Metadata & Timing**
**What it does**:
- Tracks task metadata (timestamps, sub-runs, parent executions)
- Records sub-workflow executions for AI agents
- Preserves source data context for expression resolution
- Tracks resumed executions (e.g., AI agents pausing/resuming)

**Metadata Structure**:
```typescript
export interface ITaskMetadata {
  subRun?: ITaskSubRunMetadata[]
  parentExecution?: RelatedExecution
  subExecution?: RelatedExecution
  subExecutionsCount?: number
  preserveSourceOverwrite?: boolean
  preservedSourceOverwrite?: ISourceData
  nodeWasResumed?: boolean  // AI agent pause/resume tracking
}

export interface ITaskSubRunMetadata {
  node: string
  runIndex: number
}
```

**Complexity to Port**: **MEDIUM** (80-120 hours)
- Relatively simple data structures
- Integration with execution lifecycle

**Criticality**: **ADVANCED** - Useful for observability & debugging

---

### 10. **Waiting/Pause State Management**
**What it does**:
- Manages nodes that wait for external events (e.g., webhooks)
- Maintains waiting execution stack
- Resumes execution when awaited condition is met
- Handles AI agent pause/resume cycles

**Key Methods**:
```typescript
prepareWaitingToExecution(
  nodeName: string,
  numberOfConnections: number,
  runIndex: number
)

private handleWaitingState(workflow: Workflow)
```

**Complexity to Port**: **HIGH** (150-250 hours)
- Complex state management
- Requires async coordination
- Important for webhooks and AI agents

**Criticality**: **ADVANCED** - Essential for webhook/async nodes

---

### 11. **Trigger Node Execution**
**Found in**: `workflow-execute.ts` lines ~1098+

**What it does**:
- Handles special trigger node execution
- Supports both automatic (polling) and manual triggers
- Returns manual trigger functions for testing
- Manages trigger lifecycle (start/close)

**Code Pattern**:
```typescript
private async executeTriggerNode(
  workflow: Workflow,
  node: INode,
  nodeType: INodeType,
  additionalData: IWorkflowExecuteAdditionalData,
  mode: WorkflowExecuteMode,
  inputData: ITaskDataConnections
): Promise<IRunNodeResponse>

// Returns
interface IRunNodeResponse {
  data: INodeExecutionData[][] | null
  closeFunction?: CloseFunction
}
```

**Complexity to Port**: **MEDIUM** (100-150 hours)
- Special execution path
- Lifecycle management

**Criticality**: **ADVANCED** - For trigger-based workflows

---

### 12. **Webhook Node Support**
**What it does**:
- Processes webhook node requests
- Passes data through without modification
- Delegates actual webhook handling to WebhookService
- Manages webhook path resolution

**Node Types**:
```
n8n-nodes-base.webhook
n8n-nodes-base.httpRequest (can be used as webhook)
```

**Complexity to Port**: **MEDIUM** (80-120 hours)
- Integration with external service
- Request routing

**Criticality**: **ADVANCED** - For webhook-based triggers

---

### 13. **Poll Node Support**
**Found in**: `workflow-execute.ts` lines ~1078+

**What it does**:
- Handles polling nodes that run on intervals
- Creates poll context for node execution
- Manages polling lifecycle

**Code Pattern**:
```typescript
private async executePollNode(
  workflow: Workflow,
  node: INode,
  nodeType: INodeType,
  additionalData: IWorkflowExecuteAdditionalData,
  mode: WorkflowExecuteMode,
  inputData: ITaskDataConnections
): Promise<IRunNodeResponse>
```

**Complexity to Port**: **MEDIUM** (60-100 hours)
- Similar to trigger node execution
- Scheduling/timing logic

**Criticality**: **ADVANCED** - For scheduled/polled workflows

---

### 14. **Sub-Workflow Execution**
**What it does**:
- Executes nested workflows via "Execute Workflow" node
- Manages execution context for sub-workflows
- Tracks parent-child workflow relationships
- Supports AI tool workflows (LangChain tools)

**Node Types**:
```
EXECUTE_WORKFLOW_NODE_TYPE = 'n8n-nodes-base.executeWorkflow'
EXECUTE_WORKFLOW_TRIGGER_NODE_TYPE = 'n8n-nodes-base.executeWorkflowTrigger'
WORKFLOW_TOOL_LANGCHAIN_NODE_TYPE = '@n8n/n8n-nodes-langchain.toolWorkflow'
```

**Complexity to Port**: **HIGH** (200-300 hours)
- Requires workflow nesting
- Complex context management
- AI agent integration

**Criticality**: **ADVANCED** - For modular workflows and AI agents

---

### 15. **Partial Execution Support**
**What it does**:
- Executes only portion of workflow from specified node
- Filters execution to required parent nodes
- Supports testing specific sections
- Used with pin data for development

**Methods**:
```typescript
// Partial execution filtering
findTriggerForPartialExecution()
findSubgraph()
filterDisabledNodes()
recreateNodeExecutionStack()
```

**Complexity to Port**: **HIGH** (150-200 hours)
- Complex graph analysis
- State reconstruction
- Filtering logic

**Criticality**: **ADVANCED** - Development/testing feature

---

### 16. **Execution Lifecycle Hooks**
**What it does**:
- Provides hooks for monitoring execution lifecycle
- Key hooks: `nodeExecuteBefore`, `nodeExecuteAfter`
- Skips hooks for resumed nodes (AI agents) to prevent duplicate events
- Integrates with observability/telemetry systems

**Hook Pattern**:
```typescript
// Skip nodeExecuteBefore for resumed agent nodes
if (!executionData.metadata?.nodeWasResumed) {
  await hooks.runHook('nodeExecuteBefore', [executionNode.name, taskStartedData]);
}

// Always run nodeExecuteAfter
await hooks.runHook('nodeExecuteAfter', [
  executionNode.name,
  taskData,
  this.runExecutionData,
]);
```

**Complexity to Port**: **MEDIUM** (60-100 hours)
- Event-driven architecture
- Hook registry management

**Criticality**: **ADVANCED** - For observability/debugging

---

## IMPORTANT TYPES & DATA STRUCTURES

### 17. **Task Data Structures**
**File**: `packages/workflow/src/interfaces.ts` (3527 lines)

**Key Types**:
```typescript
// Main execution result
export interface IRun {
  data: IRunExecutionData
  mode: WorkflowExecuteMode
  waitTill?: Date | null
  startedAt: Date
  stoppedAt?: Date
  status: ExecutionStatus
  jobId?: string
}

// Per-node execution results
export interface IRunData {
  [nodeName: string]: ITaskData[]  // Array handles retries/loops
}

// Single task execution
export interface ITaskData extends ITaskStartedData {
  data?: ITaskDataConnections
  inputOverride?: ITaskDataConnections
  error?: ExecutionError
  metadata?: ITaskMetadata
}

// Data connections between nodes
export interface ITaskDataConnections {
  [connectionType: string]: INodeExecutionData[][] | null
  main?: INodeExecutionData[][] | null
}

// Single item execution
export interface INodeExecutionData {
  pairedItem: IPairedItemData | IPairedItemData[]
  json: IDataObject
  binary?: IBinaryKeyData
  error?: ExecutionError
}

// Paired item tracking
export interface IPairedItemData {
  item: number | null
  sourceOverwrite?: ISourceData
}
```

**Complexity to Port**: **MEDIUM** (implement as records/variants)

**Criticality**: **CORE** - Foundation of execution data model

---

### 18. **Binary Data Support**
**What it does**:
- Handles file/binary data alongside JSON
- Supports multiple binary file types (image, audio, video, pdf, etc.)
- Manages binary data mode (combined vs separate)
- Binary data references in execution items

**Types**:
```typescript
export type BinaryFileType = 'text' | 'json' | 'image' | 'audio' | 'video' | 'pdf' | 'html'

export interface IBinaryData {
  data: string  // Base64 or reference
  mimeType: string
  fileType?: BinaryFileType
  fileName?: string
  directory?: string
  fileExtension?: string
  fileSize?: string
  bytes?: number
  id?: string
}

// In execution data
export interface INodeExecutionData {
  json: IDataObject
  binary?: IBinaryKeyData  // { [key: string]: IBinaryData }
}
```

**Complexity to Port**: **MEDIUM** (100-150 hours)
- Requires binary data handling infrastructure
- Mime type detection

**Criticality**: **ADVANCED** - For file-processing workflows

---

### 19. **Paired Item Tracking System**
**What it does**:
- Maintains data lineage through workflow
- Maps which input items produced which output items
- Supports three tracking methods:
  - `pairedItem` - direct index mapping
  - `itemMatching` - matching criteria-based
  - `item` - legacy single item
- Enables smart data joining/merging

**Usage in Expressions**:
```typescript
// Get paired item in expression
$getPairedItem(itemIndex)
$item(index)
pairedItem()
```

**Complexity to Port**: **HIGH** (120-180 hours)
- Complex lineage tracking
- Supports different tracking modes
- Performance critical

**Criticality**: **ADVANCED** - Important for complex workflows

---

### 20. **Execution Context**
**What it does**:
- Provides context during node execution
- Flow context - workflow-wide state
- Node context - node-specific state
- Manages context lifecycle

**Structure**:
```typescript
export interface IExecuteContextData {
  [key: string]: IContextObject  // "flow" | "node:<NODE_NAME>"
}

export function getContext(
  runExecutionData: IRunExecutionData,
  type: 'flow' | 'node',
  node?: INode
): IContextObject
```

**Complexity to Port**: **MEDIUM** (60-100 hours)
- Straightforward context management
- Integration with expression system

**Criticality**: **CORE** - Used throughout execution

---

## FEATURE COMPLEXITY SUMMARY TABLE

| Feature | Complexity | Hours | Criticality | Priority |
|---------|-----------|-------|------------|----------|
| Expression Evaluation | Very High | 200-300 | Core | P0 |
| Workflow Data Proxy | High | 150-200 | Core | P0 |
| Node Helpers | Medium | 100-150 | Core | P0 |
| Workflow Class | Low-Medium | 50-100 | Core | P0 |
| Execution Engine | Very High | 400-600 | Core | P0 |
| Task Data Types | Medium | 80-120 | Core | P0 |
| Execution Context | Medium | 60-100 | Core | P1 |
| Error Handling | Medium | 60-100 | Core | P1 |
| Retry Logic | Low | 20-30 | Advanced | P2 |
| Pin Data | Low | 30-50 | Advanced | P2 |
| Execution Metadata | Medium | 80-120 | Advanced | P2 |
| Wait/Pause States | High | 150-250 | Advanced | P2 |
| Trigger Nodes | Medium | 100-150 | Advanced | P2 |
| Webhook Support | Medium | 80-120 | Advanced | P2 |
| Poll Nodes | Medium | 60-100 | Advanced | P2 |
| Sub-Workflows | High | 200-300 | Advanced | P3 |
| Partial Execution | High | 150-200 | Advanced | P3 |
| Lifecycle Hooks | Medium | 60-100 | Advanced | P2 |
| Binary Data | Medium | 100-150 | Advanced | P3 |
| Paired Item Tracking | High | 120-180 | Advanced | P2 |
| **TOTAL (Core Only)** | - | **~1000-1300** | - | - |
| **TOTAL (Core + Advanced)** | - | **~2500-3500** | - | - |

---

## PORTING RECOMMENDATIONS

### Phase 1: CORE (Foundation)
1. Task data types (IRun, IRunData, ITaskData, INodeExecutionData)
2. Basic Workflow class structure
3. Node Helpers (parameter resolution)
4. Basic execution engine (orchestration loop)
5. Expression evaluator (simplified or use existing)

### Phase 2: ESSENTIAL EXECUTION
6. Error handling per node
7. Retry logic
8. Execution context management
9. Workflow Data Proxy (data access)

### Phase 3: WORKFLOW FEATURES
10. Pin data system
11. Lifecycle hooks
12. Execution metadata
13. Paired item tracking
14. Wait/pause states

### Phase 4: ADVANCED
15. Trigger node execution
16. Webhook support
17. Poll node support
18. Sub-workflow execution
19. Partial execution support
20. Binary data handling

---

## POTENTIAL CHALLENGES & SOLUTIONS

### 1. **Expression Evaluation Security**
**Challenge**: Sandboxing malicious JavaScript
**Solution**: 
- Use existing expression evaluator (n8n's @n8n/expression-runtime)
- Implement whitelist-based approach
- Consider VM-based isolation if available in MoonBit ecosystem

### 2. **Async/Await Complexity**
**Challenge**: Managing async execution with timeouts, cancellation, retries
**Solution**:
- Use MoonBit's effect system for async handling
- Implement timeout mechanisms at the execution engine level
- Use structured concurrency patterns

### 3. **Type System Differences**
**Challenge**: TypeScript's flexible typing vs MoonBit's strict types
**Solution**:
- Map generic `IDataObject` to MoonBit's map/record types
- Use variants for union types
- Create type wrappers for flexibility

### 4. **Performance for Large Datasets**
**Challenge**: Processing large item arrays efficiently
**Solution**:
- Lazy evaluation of execution data
- Stream processing for large item batches
- Efficient paired item tracking (consider indices instead of copying)

### 5. **Execution State Management**
**Challenge**: Maintaining complex execution state across retries, waits, partial execution
**Solution**:
- Immutable execution state with versioning
- Snapshot-based state management
- Transaction-like execution steps

---

## MINIMAL VIABLE PRODUCT (MVP) SCOPE

To enable basic workflow execution in MoonBit, focus on:

1. ✅ **Workflow Class** - Node/connection management
2. ✅ **Task Data Types** - Execution data model
3. ✅ **Basic Execution Engine** - Sequential node execution
4. ✅ **Node Helpers** - Parameter resolution
5. ✅ **Simple Expression Evaluation** - Parameter value expressions
6. ✅ **Error Handling** - Per-node error capture
7. ✅ **Execution Context** - Access to previous node outputs

**Estimated MVP Effort**: 800-1000 hours

This provides a solid foundation for executing simple to moderate workflows.
