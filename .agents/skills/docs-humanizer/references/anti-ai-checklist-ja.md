# Japanese Anti-AI Writing Checklist

Source summary for this skill:

- Zenn article: <https://zenn.dev/m0370/articles/205c9340a418c3>
- Wikipedia reference chain:
  - <https://en.wikipedia.org/wiki/Wikipedia:Signs_of_AI_writing>
  - <https://en.wikipedia.org/wiki/Wikipedia:WikiProject_AI_Cleanup>
- Upstream skills:
  - <https://github.com/blader/humanizer>
  - <https://github.com/matsuikentaro1/humanizer_academic>

This checklist is a Japanese adaptation for repository documentation. It is intentionally shorter and more operational than the original article.

## Core Principle

The goal is not “make the text less polished.” The goal is:

- remove patterns that signal generic LLM output
- keep the document concrete and technically accountable
- restore authorial judgment where it clarifies tradeoffs

## 16 Checks

1. Avoid overstating significance.
   - Cut phrases that inflate meaning without adding evidence: `重要性`, `画期的`, `大きな示唆`, `注目されます`.
   - If the point matters, say what changed and why it matters in concrete terms.

2. Reduce repeated AI-frequent transitions.
   - Watch for repeated `さらに`, `加えて`, `一方で`.
   - Many of these can be deleted with no loss.

3. Remove “appended significance” clauses.
   - Typical pattern: fact first, then `〜を浮き彫りにしており`, `〜を示唆しており`.
   - Leave the fact alone unless the implication is truly necessary.

4. Prefer simple predicates over roundabout copula avoidance.
   - Replace `〜として位置づけられます`, `〜の役割を果たします` with plainer forms when possible.
   - If the sentence just means `〜です`, write `〜です`.

5. Avoid empty synonym rotation.
   - Do not restate the same point with near-synonyms just to sound varied.
   - Compress two weak sentences into one factual sentence.

6. Be suspicious of forced “three-item” lists.
   - Many AI outputs create lists of three even when two or four would be more accurate.
   - Match the structure to the actual content.

7. Kill templated intros and conclusions.
   - Avoid openings like `ここでは〜を解説します`.
   - Avoid endings like `今後の展開が注目されます`.
   - Start with the actual problem. End with the actual outcome or remaining risk.

8. Ban em dash and fullwidth dash by default.
   - Replace `—` / `――` / `——` style insertions with commas, parentheses, or sentence splits.

9. Replace vague sourcing.
   - Phrases like `〜と言われています`, `〜とされています` need a source or a rewrite.
   - Prefer direct attribution, observed behavior, or a linked reference.

10. Cut excessive hedging.
   - Watch `可能性があります`, `かもしれません`, `と思われます`, `と考えられます`.
   - Keep uncertainty only when it is technically real and relevant.

11. Avoid mechanical bold.
   - Repeated `**label**:` bullets often read like chatbot output.
   - Use a normal bullet or convert the point into prose.

12. Avoid inline-heading bullets.
   - `- 速度: ...` and `- 品質: ...` are often too schematic.
   - Either make them proper subsections or rewrite as ordinary bullets.

13. Remove chatbot residue.
   - Delete phrases like `もちろん`, `以下にまとめます`, `ご質問の`, `ご安心ください`.
   - Repository documents are not chat replies.

14. Remove sycophantic tone.
   - Avoid praise-first phrasing or empty affirmation.
   - Prefer direct technical statements.

15. Put some “soul” back into the document.
   - When a judgment matters, state it specifically.
   - Good repository docs can sound opinionated if the opinion is grounded in observed tradeoffs.

16. Run an anti-AI self-audit at the end.
   - Re-read the opening and closing sections first.
   - Ask: “Which lines still feel like default LLM prose?”
   - Revise those lines before finalizing.

## Mechanical Audit Coverage

`scripts/audit-docs.sh` only covers a subset:

- dash usage
- inline-heading bullets
- chatbot residue
- templated intros/conclusions
- over-hedging
- vague sourcing
- AI-frequent vocabulary
- significance inflation
- bold-overuse hints

It does **not** reliably catch:

- weak overall rhythm
- empty synonym rotation
- forced three-part structure in subtle prose
- whether a document has enough concrete judgment

Those still require a human editorial pass.
