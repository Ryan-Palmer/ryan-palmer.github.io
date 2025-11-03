---
layout: post
title:  "Document Extraction with Microsoft Agent Framework"
date:   2025-11-03 13:51:46 +0000
---

# Introduction

- State use case immediately: "Extracting structured contract details from PDF files"
- Why agentic? Because loosely specified, hard to deterministically code, requires contextual doc understanding.
- Why MAF? Evolution of AutoGen and SK, based on primitives, use any model anywhere, enterprise features with AIFoundry (Entra, billing, content management, monitoring etc).

# How to access LLM?
    - Local with LM Studio
        - Gemma3 (vision)
        - Qwen3
        
# How to get data out of PDFs?
    - Text extraction with PDFPig (?)
    - Image extraction (with ?) and recognition with vision model

# How to give data to LLM?
    - RAG
        - Embed
        - Vector Store
        - Search Tool
        - Author / Critic
    - All in context

# Solution
    - GPT-5-Mini hosted in AI Foundry
    - OpenAPI Responses API allows direct PDF bytes upload - text extraction and image recognition all done server-side
    - All in context - a few pages (270KB) of PDF not too much for current models, simpler / cheaper / more reliable (?) than RAG.

# Validation
    - Required to go beyond prototype
    - Console output limited
    - Dedicated application to enable
        - Ingestion
        - Labelling
        - Extraction
        - Validation
    - Immediate value vs manual
    - Building automated eval capability
