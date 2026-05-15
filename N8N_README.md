# n8n TypeScript Workflow Source Exploration

This directory contains analysis of n8n's TypeScript workflow execution system, with recommendations for porting valuable features to MoonBit.

## 📄 Documents

### 1. **N8N_EXPLORATION_SUMMARY.md** (Executive Summary)
Start here. Overview of findings, key insights, and recommendations.
- Architecture overview
- Feature categorization (core vs. advanced)
- Effort estimates and timeline
- Risk analysis and mitigation
- Recommended porting strategy

**Read this for**: Quick understanding of what's valuable and why

### 2. **N8N_QUICK_REFERENCE.md** (Implementation Guide)
Quick reference for developers planning implementation.
- Top 10 most valuable features
- Implementation order (4-phase plan)
- Code examples and patterns
- Security considerations
- Dependencies and alternatives
- Estimated LOC breakdown

**Read this for**: Planning implementation and understanding patterns

### 3. **N8N_FEATURES_ANALYSIS.md** (Detailed Technical Analysis)
In-depth analysis of each feature with code samples.
- 20 features with detailed descriptions
- Complexity ratings (LOW, MEDIUM, HIGH, VERY HIGH)
- Hours to implement for each feature
- Criticality levels (CORE, ADVANCED)
- Code examples from n8n source
- Feature dependency relationships
- Implementation challenges and solutions

**Read this for**: Deep understanding of each feature

---

## 🎯 Quick Summary

### What Was Analyzed
- 6 key TypeScript source files (~95,000 lines total)
- n8n's workflow execution engine
- Expression evaluation system
- Execution data model
- Node parameter resolution
- Error handling and retry logic
- Advanced features (sub-workflows, hooks, etc.)

### Key Findings

**Core Features (Essential for MVP)**:
1. Workflow & node graph management
2. Execution data model (IRun, ITaskData types)
3. Basic execution loop
4. Parameter resolution
5. Expression evaluation with sandboxing
6. Error handling
7. Execution context

**Estimated MVP Effort**: 800-1,000 hours (2-3 months)

**Estimated Full Feature Set**: 3,500-4,500+ hours (9-12+ months)

### Implementation Phases

| Phase | Duration | Effort | Deliverable |
|-------|----------|--------|-------------|
| **Phase 1: Foundation** | 2-3 mo | 800-1000 hrs | Simple 2-3 node workflows |
| **Phase 2: Usability** | 1-2 mo | 400-500 hrs | Workflows with dynamic parameters |
| **Phase 3: Reliability** | 2-3 mo | 500-700 hrs | Production-ready for common use cases |
| **Phase 4: Advanced** | 3+ mo | 1000+ hrs | Feature parity with basic n8n |

### Top 3 Most Valuable Features

1. **Execution Engine Architecture** - Sequential stack-based execution model that's clean and extensible
2. **Expression Evaluation** - Sandboxed parameter evaluation supporting dynamic node configuration
3. **Data Proxy Access** - Elegant proxy-based data access pattern for accessing previous node outputs

### Top 3 Most Complex Features

1. **Expression Evaluator** (200-300 hrs) - Security sandboxing is critical and non-trivial
2. **Execution Engine** (400-600 hrs) - Handles retries, waits, partial execution, hooks
3. **Workflow Data Proxy** (150-200 hrs) - Complex proxy objects with lazy evaluation and paired item tracking

---

## 🚀 Getting Started

### For Planners
1. Read **N8N_EXPLORATION_SUMMARY.md** for overview
2. Check **N8N_QUICK_REFERENCE.md** for timeline and effort
3. Review **N8N_FEATURES_ANALYSIS.md** for specific features you're interested in

### For Developers
1. Start with Phase 1 checklist in **N8N_QUICK_REFERENCE.md**
2. Refer to code examples in **N8N_FEATURES_ANALYSIS.md** for patterns
3. Implementation examples:
   - Data types: Section 17 in detailed analysis
   - Execution loop: Section 5 in detailed analysis
   - Expression evaluation: Section 1 in detailed analysis

### For Architects
1. Review architecture in **N8N_EXPLORATION_SUMMARY.md** section 1
2. Check complexity matrix in **N8N_FEATURES_ANALYSIS.md**
3. Review patterns section in **N8N_EXPLORATION_SUMMARY.md**

---

## 📊 Feature Overview

### Core Features (Must-Have)
- ✅ Workflow graph (nodes & connections)
- ✅ Execution data model
- ✅ Basic execution engine
- ✅ Parameter resolution
- ✅ Expression evaluation
- ✅ Error handling
- ✅ Execution context

### Advanced Features (Nice-to-Have)
- ⭐ Retry logic with exponential backoff
- ⭐ Pin data for testing/debugging
- ⭐ Lifecycle hooks for observability
- ⭐ Waiting/pause states
- ⭐ Trigger nodes
- ⭐ Webhook support
- ⭐ Poll nodes
- ⭐ Sub-workflow execution
- ⭐ Partial execution support
- ⭐ Binary data handling
- ⭐ Paired item tracking (data lineage)

See **N8N_FEATURES_ANALYSIS.md** for detailed descriptions of each.

---

## 💡 Key Insights

### Architecture Pattern
```
Data Types (interfaces)
    ↓
Workflow Container (graph management)
    ↓
Execution Engine (orchestration)
    ↓
Supporting Services:
  - Node Helpers (parameters)
  - Data Proxy (data access)
  - Expression Evaluator (dynamic values)
```

### Execution Model
- **Stack-based**: Nodes queued in `nodeExecutionStack`, executed sequentially
- **Item-based**: Each node processes array of items, produces array of results
- **Error-tolerant**: Errors stored in execution data, don't stop flow
- **Resumable**: Supports pausing for external events (webhooks, delays)

### Key Patterns to Adopt
1. Execution stack pattern (clean, resumable)
2. Proxy data access (efficient, lazy)
3. Structured errors (flows through execution)
4. Metadata tracking (enables observability)
5. Hook system (decouples concerns)

---

## ⚠️ Important Considerations

### Security
- Expression evaluation must be sandboxed (no eval, require, etc.)
- Whitelist approach preferred over blacklist
- Regular security audits recommended

### Performance
- Large workflows: Use streaming for item arrays
- Large data: Lazy evaluation in data proxy
- Memory: Clean up between nodes, efficient paired item tracking

### Type System
- TypeScript's dynamic typing → MoonBit's strict types
- Use Map<String, Value> or Record types for flexibility
- Accept some type safety loss for usability

### Complexity
- Expression evaluator: Most security-critical component
- Execution engine: Most complex logic
- Data proxy: Most performance-sensitive

---

## 📚 Reference

### Source Repository
- **GitHub**: https://github.com/n8n-io/n8n
- **Local**: `repos/n8n`

### Key Files Analyzed
| File | Lines | Purpose |
|------|-------|---------|
| workflow.ts | 925 | Workflow container |
| workflow-data-proxy.ts | 1,586 | Data access |
| node-helpers.ts | 1,980 | Parameter resolution |
| expression.ts | 595 | Expression evaluation |
| interfaces.ts | 3,527 | Type definitions |
| workflow-execute.ts | 86,225 | Execution engine |

### Related Technologies
- **DateTime**: Luxon library
- **Expression Runtime**: @n8n/expression-runtime (optional, can build custom)
- **Async**: MoonBit effects/continuations
- **Types**: MoonBit records, variants, maps

---

## 🤔 FAQ

**Q: What's the minimum viable product?**  
A: Core features (Phase 1+2) enable basic workflow execution. 800-1,500 hours.

**Q: What's the hardest part?**  
A: Expression evaluation with proper security, and managing complex async execution state.

**Q: Can we use n8n's code directly?**  
A: Not directly (TypeScript → MoonBit), but the architecture and patterns are directly portable.

**Q: How long to build?**  
A: MVP: 2-3 months. Production: 6-9 months. Full feature: 9-12+ months.

**Q: What's the biggest risk?**  
A: Expression evaluation security and complex async state management.

---

## 📝 Notes

- Analysis conducted: March 13, 2024
- Files examined: 6 TypeScript files, ~95,000 lines
- Features identified: 20 features (7 core, 13 advanced)
- Complexity range: LOW (20-30 hrs) to VERY HIGH (400-600 hrs)
- Total effort estimate: 2,500-3,500 hours for full implementation

---

**For questions or discussions about implementation, refer to the detailed analysis documents.**
