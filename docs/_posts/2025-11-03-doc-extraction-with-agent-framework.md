---
layout: post
title:  "Document Extraction with Microsoft Agent Framework"
date:   2025-11-03 13:51:46 +0000
---

# The task

I was recently presented with a great task at [Wieldmore](https://www.wieldmore.com/). I say great because it felt like the perfect combination of challenging but tractable.

The question, at least on the surface, was simple - can we use AI to speed up the time consuming, manual process of looking through financial contract PDFs and picking out the values and terms for booking into our analytics platform, [Pomelo](https://www.wieldmore.com/pomelo).

This kind of task is a great use case for LLMs / v(ision)LLMs as it leans into their strengths - understanding the context of a document. It is also something for which it would be extremely difficult if not impossible to program a manual routine - the variation in layout and content of the documents is just too vast to parse deterministically.


# Getting started

Throughout 2025 the tools and capabilities of models and frameworks have been developed at what feels like breakneck speed. It can feel a bit overwhelming and hard to know where to start.

I began by breaking the task into a series of questions:

- How can I access LLMs?
- What APIs are available?
- How do I configure their behaviour?
- How do I pass them data?
- How do I know they are working correctly?

Attempting to answer these questions has really helped me to understand the ecosystems and tooling available, which I found surprisingly accessible and intuitive once I got hands on with them.


# How to access LLMs?

Perhaps the most obvious first question was "Where can I access LLMs for experimentation?".

We have a choice of running them locally or remotely.

I am lucky enough to have a pretty capable PC which can run many of the open source models available on platforms such as [Hugging Face](https://huggingface.co/) and I figured "If I can get it working on a small, local model then a large, remote model should have no problem".

I did briefly experiment with [Ollama](https://ollama.com/) along with [OpenWebUI](https://openwebui.com/) for local model hosting and configuration, but I really enjoyed the experience of using [LM Studio](https://lmstudio.ai/) so selected this as my local model hosting solution. It has a really intuitive interface which makes discovering, installing and experimenting with models a breeze.

For the upcoming experiments I needed models which supported vision, reasoning and tool use.

I did a quick run of experiments against the top models available in LM Studio and it became pretty obvious that the best vision model I could run was by far [Gemma 3 27B](https://lmstudio.ai/models/google/gemma-3-27b).

It was also great at reasoning and ok with tool use, however I also had strong results here with [Qwen3 32B](https://lmstudio.ai/models/qwen/qwen3-32b).

> Since then many other models have been released, such as OpenAI's GPT OSS 120B which is much more resource intensive but can still be run on a high-end home PC.


# Microsoft Agent Framework

Although a .NET and web developer by trade, I often turn to Python when working with ML / AI projects. For this project however, I decided see what Microsoft had available. This would facilitate integration with our existing F# / Azure stack.

As is often the case, they had a vast array of slightly confusingly overlapping and loosely defined products and services at various levels of abstraction. To add to the fun, many of them were in preview and only partially documented.

At the time I started the project, the framework which formed the core, 'AI primitives' foundation of the stack was [Semantic Kernel](https://learn.microsoft.com/en-us/semantic-kernel/overview/).

This has been around for a while and had recently spawned it's [Agent Framework](https://learn.microsoft.com/en-us/semantic-kernel/frameworks/agent/?pivots=programming-language-csharp) which embraced the building blocks famousely laid out in Anthropic's [Building Effective Agents](https://www.anthropic.com/engineering/building-effective-agents) paper.

As I progressed through the project, the new [Microsoft Agent Framework](https://learn.microsoft.com/en-us/agent-framework/overview/agent-framework-overview) was announced.

Whilst this did initially bring to mind the famous XKCD on [Standards](https://xkcd.com/927/), it actually allows the SK team to merge with the [AutoGen](https://microsoft.github.io/autogen/stable//index.html) folk to work on a unified, modern platform.

There is an awesome [series of videos](https://www.youtube.com/playlist?list=PLhGl0l5La4sYXjYOBv7h9l7x6qNuW34Cx) on YouTube which show practical examples of migration process from SK and how to use all the features of the new framework. I'd highly recommed it as your first point of call for any more information on the approaches discussed in this blog.


# How to get data out of PDFs?

PDF is a notoriously difficult format to work with. It is more of an image than a document, although it has elements of both.

My first instinct was to try to extract the text from the document.

I found a great library called [PDFPig](https://github.com/UglyToad/PdfPig) which supported text extraction from PDFs in .NET. It uses a number of algorithms to determine the arrangement of the text and chunks it along with x/y coordinates deternining it's position on the page.

As effective as the library was, I found that the data quickly exceeded the context length of the LM Studio models on my machine.

I decided to try feeding images of the PDFs directly to Gemma 3, as it is a vLLM. It showed strong performance compared to the text extraction approach, getting the details mostly correct, most of the time. Given the tiny size of this model, I felt this was very encouraging.


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
