# Research Directive: Study llama.cpp Tokenizer for HolyC Port

## Trigger
BPE tokenization in HolyC requires Unicode handling, regex pre-tokenization, and merge priority queues — all without libc. This is ~2,000 lines of careful code. The inference agent needs concrete guidance.

## Research Required
The Sanhedrin MUST study llama.cpp's tokenizer and document:

1. **Source file**: `llama.cpp` function `llama_tokenize()` and `llm_tokenizer_bpe`
   - How does it load vocab from GGUF? Which metadata keys?
   - What's the merge table format? How are merge priorities ordered?

2. **Pre-tokenization regex** — llama.cpp uses a regex to split input into pre-tokens before BPE. What regex pattern? How to implement this in HolyC without regex library? (Character-class-based state machine is the answer)

3. **Unicode handling** — LLaMA tokenizers work on UTF-8 byte sequences. HolyC uses ASCII. Options:
   - Treat input as raw bytes (simplest, works for English)
   - Implement minimal UTF-8 decode (needed for non-ASCII languages)
   - Recommendation: raw bytes first, UTF-8 later

4. **Special tokens** — BOS (beginning of sequence), EOS (end of sequence), UNK (unknown). How does llama.cpp handle these? What are the token IDs for LLaMA/TinyLlama?

5. **BPE merge algorithm** — the core loop:
   ```
   while merges possible:
     find highest-priority adjacent pair
     merge them into single token
   ```
   In HolyC this needs: a doubly-linked list of tokens, a priority lookup table (hash map or sorted array), and efficient pair finding.

6. **Validation strategy** — how to verify our tokenizer matches llama.cpp:
   - Tokenize 100 known strings with llama.cpp, save token ID sequences
   - Run same strings through HolyC tokenizer, compare output
   - Any mismatch = bug

## Action
Write findings to this file. The inference agent reads this each iteration and should implement WS6 based on these findings.
