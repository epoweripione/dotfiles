## Mirrors
###  [Huggingface.co](https://hf-mirror.com/docs/huggingface_hub/guides/download#download-from-the-cli)
- [HF-Mirror](https://hf-mirror.com/)
```bash
# huggingface-cli
pip install -U huggingface_hub

# hfd
wget https://hf-mirror.com/hfd/hfd.sh && chmod a+x hfd.sh

# Linux
export HF_ENDPOINT=https://hf-mirror.com

# Windows Powershell
$env:HF_ENDPOINT = "https://hf-mirror.com"

# Python script
HF_ENDPOINT=https://hf-mirror.com python your_script.py

# Models
huggingface-cli download --resume-download Qwen3-8B --local-dir Qwen3-8B
./hfd.sh Qwen3-8B

# Datasets
huggingface-cli download --repo-type dataset --resume-download clean-wikipedia --local-dir clean-wikipedia
./hfd.sh clean-wikipedia --dataset

# Gated Repo Access Token
huggingface-cli download --token hf_*** --resume-download meta-llama/Llama-2-7b-hf --local-dir Llama-2-7b-hf
./hfd.sh meta-llama/Llama-2-7b --hf_username YOUR_HF_USERNAME --hf_token hf_***
```

- [AI 快站](https://aifasthub.com/models)
```bash
# huggingface-cli
pip install -U huggingface_hub

# hf-fast
wget https://fast360.xyz/images/hf-fast.sh && chmod a+x hf-fast.sh

# Linux
export HF_ENDPOINT=https://aifasthub.com

# Windows Powershell
$env:HF_ENDPOINT = "https://aifasthub.com"

# Python script
HF_ENDPOINT=https://aifasthub.com python your_script.py

# Models
huggingface-cli download --resume-download Qwen3-8B --local-dir Qwen3-8B
./hf-fast.sh Qwen3-8B

# Datasets
huggingface-cli download --repo-type dataset --resume-download clean-wikipedia --local-dir clean-wikipedia
./hf-fast.sh clean-wikipedia --dataset

# Gated Repo Access Token
huggingface-cli download --token hf_*** --resume-download meta-llama/Llama-2-7b-hf --local-dir Llama-2-7b-hf
./hf-fast.sh meta-llama/Llama-2-7b --hf_username YOUR_HF_USERNAME --hf_token hf_***
```

- [Huggingface mirror download](https://github.com/git-cloner/aliendao)

- [Gitee AI](https://ai.gitee.com/models)

- [始智 AI wisemodel](https://wisemodel.cn/model)


### [Ollama](https://ollama.com/)
- [ModelScope](https://modelscope.cn/docs/models/advanced-usage/ollama-integration)
- [Onllama.ModelScope2Registry](https://github.com/onllama/Onllama.ModelScope2Registry)
```bash
ollama run aifasthub.com/{username}/{reponame}:GGUF-hardware-compatibility

ollama run modelscope.cn/Qwen/Qwen3-8B-GGUF:Q4_K_M
ollama run modelscope.cn/google/gemma-3-12b-it-qat-q4_0-gguf:Q4_0
```

- [AI 快站](https://aifasthub.com/models)
```bash
ollama run aifasthub.com/{username}/{reponame}:GGUF-hardware-compatibility

ollama run aifasthub.com/Qwen/Qwen3-8B-GGUF:Q4_K_M
ollama run aifasthub.com/google/gemma-3-12b-it-qat-q4_0-gguf:Q4_0
```

- [Gitee AI](https://ai.gitee.com/models)

- [始智 AI wisemodel](https://wisemodel.cn/model)
