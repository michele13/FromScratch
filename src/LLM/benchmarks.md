# Local LLM Benchmark Results

| Modello | Dimensione | Backend | pp512 (t/s) | tg128 (t/s) |
|---------|-----------|---------|-------------|-------------|
| **Qwen3.5 0.8B BF16** | 1.40 GiB | Vulkan | 40.28 | 8.92 |
| **Qwen3.5 0.8B BF16** | 1.40 GiB | CPU | 76.93 | 6.24 |
| **LFM2 1.2B Q8_0** | 1.16 GiB | Vulkan | 25.58 | 5.91 |
| **LFM2 1.2B Q8_0** | 1.16 GiB | CPU | 52.12 | 7.53 |
| **LFM2 1.2B Q4_0** | 661 MiB | Vulkan | 25.58 | 12.33 |
| **LFM2 1.2B Q4_0** | 661 MiB | CPU | 95.21 | 13.94 |
| **Qwen3 1.7B Q4_K - Medium** | 1.19 GiB | Vulkan | 25.58 | 6.91 |
| **Qwen3 1.7B Q4_K - Medium** | 1.19 GiB | CPU | 54.79 | 7.70 |
| **Qwen3.5 4B Q4_K - Medium** | 2.51 GiB | Vulkan | 25.58 | 2.69 |
| **Qwen3.5 4B Q4_K - Medium** | 2.51 GiB | CPU | 20.79 | 2.91 |

```
Qwen2.5-0.5B-Q4_K_M  15.45 t/s
Qwen2.5-0.5B-Q8_0    12.56 t/s
Qwen3.5-0.8B-Q4_K_M  10.00 t/s
Llama-3.2-1B-Q4_K_M   8.92 t/s
Qwen3.5-0.8B-Q4_K_M   8.46 t/s
Qwen2.5-0.5B-Q4_K_M   8.18 t/s
Llama-3.2-1B-Q4_K_M   7.07 t/s (Vulkan?)
Llama-3.2-1B-Q8_0     4.10 t/s
Llama-3.2-3B-Q4_K_M   3.87 t/s 
Llama-3.2-3B-Q4_K_M   2.91 t/s (Vulkan=)





```