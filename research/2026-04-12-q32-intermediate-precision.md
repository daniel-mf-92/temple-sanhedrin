# Research Directive: Q32 Intermediate Precision for Accumulator Path

## Trigger
The inference engine uses Q16 (16-bit fixed-point) for all math. When chaining through 22+ transformer layers, each layer's ~1% error compounds to ~24% drift. The accumulator path in matmul and attention needs wider precision.

## Research Required
The Sanhedrin MUST research and document:

1. **GGML's actual accumulator width** — what does llama.cpp use for intermediate sums in quantized dot products? (Hint: it uses 32-bit integer accumulators for Q4_0/Q8_0 dot products)

2. **Q32 fixed-point design** — define a Q16.16 or Q8.24 format for intermediate tensor values. The final output per layer can be downscaled back to Q16, but matmul inner loops and attention score accumulation should stay Q32.

3. **Where to widen** — identify the exact code paths in the inference engine that need Q32:
   - `Q4_0DotProductBlocksQ32` accumulator (src/quant/q4_0_dot.HC)
   - `Q8_0DotProductBlocksQ32` accumulator (src/quant/q8_0_dot.HC)
   - Matmul output accumulation (WS4, not yet built)
   - Attention score computation before softmax (WS5-02)
   - RMSNorm variance accumulation (src/math/rmsnorm.HC)

4. **Overflow analysis** — for a 4096-dim dot product with Q32 accumulator, what's the max possible value? Does it fit in I64? (4096 * 127 * 127 * 65536 = ~4.2e15, fits in I64 which holds 9.2e18)

## Action
Write findings to this file. The inference agent reads Sanhedrin research/ directory each iteration.
