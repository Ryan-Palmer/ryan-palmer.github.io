---
layout: post
title:  "Document Extraction with Microsoft Agent Framework"
date:   2025-11-03 13:51:46 +0000
---

# The task

I was recently presented with a great task at [Wieldmore](https://www.wieldmore.com/). It felt like the perfect combination of challenging but tractable.

The question, at least on the surface, was simple - can we use AI to speed up the time consuming, manual process of looking through financial contract PDFs and picking out the values and terms for booking into our analytics platform, [Pomelo](https://www.wieldmore.com/pomelo)?

This kind of task is a great use case for LLMs / v(ision)LLMs as it leans into their strengths - understanding the context of a document. It is also something for which it would be extremely difficult if not impossible to program a manual routine - the variation in layout and content of the documents is just too vast to parse deterministically.


# Getting started

Throughout 2025 the tools and capabilities of models and frameworks have been developed rapidly. It can feel a bit overwhelming and hard to know where to start.

I began by breaking the task into a series of questions:

- How can I access LLMs for inference?
- What APIs are available?
- How do I configure their behaviour?
- How do I pass them data?
- How do I know they are working correctly?

Attempting to answer them has really helped me to understand the ecosystems and tooling available, which I found surprisingly accessible and intuitive once I got hands on.


# How to access LLMs?

Perhaps the most obvious first question was "Where can I access LLMs for experimentation?".

We have a choice of running them locally or remotely.

I am lucky enough to have a pretty capable PC which can run many of the open source models available on platforms such as [Hugging Face](https://huggingface.co/) and I figured "If I can get it working on a small, local model then a large, remote model should have no problem". It also has the advantage of being free, other than the power.

I did briefly experiment with [Ollama](https://ollama.com/) along with [OpenWebUI](https://openwebui.com/) for local model hosting and configuration, but I really preferred the experience of using [LM Studio](https://lmstudio.ai/) so settled on this as my platform. It has a really intuitive interface which makes discovering, installing and experimenting with models a breeze.

For the upcoming experiments I needed models which supported vision, reasoning and tool use.

I did a quick run of experiments against the top models available in LM Studio and it became pretty obvious that the best vision model my machine could support was [Gemma 3 27B](https://lmstudio.ai/models/google/gemma-3-27b).

Gemma 3 was also great at reasoning and ok with tool use, however I also had strong results for these use cases with [Qwen3 32B](https://lmstudio.ai/models/qwen/qwen3-32b).

> Since then many other models have been released, such as OpenAI's GPT OSS 120B which is much more resource intensive but can still be run on a high-end home PC.


# Microsoft Agent Framework (and Semantic Kernel)

Although a .NET developer by trade, I often turn to Python when working with ML / AI projects. For this project however, I decided see what Microsoft had available. This would facilitate integration with our existing F# / Azure stack.

As is often the case, they had a vast array of slightly confusingly overlapping and loosely defined products and services pitched at various levels of abstraction. To add to the fun, many of them were in preview and only partially documented.

At the time I started the project, the framework which formed the core of the stack was [Semantic Kernel](https://learn.microsoft.com/en-us/semantic-kernel/overview/).

This has been around for a while and had recently spawned its [Agent Framework](https://learn.microsoft.com/en-us/semantic-kernel/frameworks/agent/?pivots=programming-language-csharp) which embraced the building blocks famously laid out in Anthropic's [Building Effective Agents](https://www.anthropic.com/engineering/building-effective-agents) paper.

As I progressed through the project, the new [Microsoft Agent Framework](https://learn.microsoft.com/en-us/agent-framework/overview/agent-framework-overview) was announced as a replacement for Semantic Kernel and [AutoGen](https://microsoft.github.io/autogen/stable//index.html).

Whilst this did initially bring to mind the famous XKCD on [Standards](https://xkcd.com/927/), it has allowed the teams to merge in order to work on a unified, modern platform.

I've since ported all my Semantic Kernal code across to Microsoft Agent Framework and the new API is generally much nicer, although still in preview. The devs are really active and helpful with [issues on Github](https://github.com/microsoft/agent-framework/issues).

There is an awesome [series of videos](https://www.youtube.com/playlist?list=PLhGl0l5La4sYXjYOBv7h9l7x6qNuW34Cx) on YouTube which show practical examples of migration process from SK and how to use all the features of the new framework. I'd highly recommed it as your first point of call for any more information on the approaches discussed in this blog.


# How to get data out of PDFs?

PDF is a notoriously difficult format to work with. It is more of an image than a document, although it has elements of both.

My first instinct was to try to extract the text from the document.

I found a richly featured library called [PDFPig](https://github.com/UglyToad/PdfPig) which supported text extraction from PDFs in .NET. It uses a number of algorithms to determine the arrangement of the text and chunks it along with x/y coordinates determining its position on the page.

As effective as the library was, I found that the sheer volume of data quickly exceeded the context length of the LM Studio models on my machine.


# Retrieval Augmented Generation (RAG)

The excessive size of the complete document content overflowing the context led to me experimenting with Retrieval Augmented Generation (RAG). This is just a fancy name for storing data in a database, usually with vector embedding support, and searching for relevant information when needed rather than trying to cram it all into the model's short term memory.

> An [embedding](https://www.datacamp.com/blog/vector-embedding) is essentially a numerical representation of the 'meaning' of an item of data, allowing you to understand how it relates to other items.

Semantic Kernel provided a 'connector' for a vector database called [Qdrant](https://learn.microsoft.com/en-us/semantic-kernel/concepts/vector-store-connectors/out-of-the-box-connectors/qdrant-connector?pivots=programming-language-csharp) which simplifies connecting to and interacting with an instance.

> You can launch Qdrant easily [using Docker](https://qdrant.tech/documentation/quickstart/)

I manually serialised the extracted document chunks and posted them to the LM Studio [embedding endpoint](https://lmstudio.ai/docs/python/embedding) to get their vectors. A DTO model was [defined with attributes](https://learn.microsoft.com/en-us/semantic-kernel/concepts/vector-store-connectors/out-of-the-box-connectors/qdrant-connector?pivots=programming-language-csharp#property-name-override) from `Microsoft.Extensions.VectorData` identifying the primary key, data and the embedding fields which allows data to be inserted into the Qdrant store and subsequently queried and rehydrated.

With all this set up I could embed a query, such as "What is the notional amount of the swap?", then search Qdrant for document chunks which are related to that query. This dramatically reduces the amount of data you need to send to the contract extraction LLM, as in theory you have filtered for relevant information. It could also, again theoretically, improve the quality of results as you have kept the LLM's attention on the important stuff.


# Agentic Search

Initial tests showed some success, but naturally led to the question of how many results to ask the vector database for? Too few and you might not get the info you need, and too many will inflate the context length and add noisy information, defeating the point of implementing the search.

One answer to this is rather than search for the chunks ourselves, just give the LLM a tool which allows it to search the store for itself and instruct it to keep searching until it finds what it needs. Semantic Kernel makes this easy by passing the Qdrant store to an instance of their [VectorStoreTextSearch plugin](https://learn.microsoft.com/en-us/semantic-kernel/concepts/text-search/text-search-vector-stores?pivots=programming-language-csharp#using-a-vector-store-with-text-search) which can then be registered as a tool for the LLM.

I also sped up the process of embedding the documents by implementing an [`IEmbeddingGenerator`](https://learn.microsoft.com/en-us/dotnet/api/microsoft.extensions.ai.iembeddinggenerator-2?view=net-9.0-pp) tailored to the LM Studio embedding API. By passing this to the Qdrant connector the embeddings would be automatically requested and populated when inserting an item, removing the need for me to manually request them from LM Studio.

At the time I found Qwen 3 was the most consistently successful at using the tool.


# Vision!

After playing with the text extraction for a while with mixed results, a thought came to me - maybe I can just *show* a vision model pictures of the document? 

That would give it the text information along with all the important visual clues as to how the blocks relate. I could ask it to extract, label and summarise the information for me. Surely that was too much for a tiny local model?

I converted a contract to a series of PNGs, prepared them as ImageContent for a chat message and sent them to Gemma 3. I was amazed when, after a few tweaks to the prompt, the document chunks it returned performed better with the agentic search than any of my raw text based runs.

Inspection of the chunks in the vector store showed that they were mostly well extracted, labeled and described.

To further speed up the chunk extraction process I exposed the Qdrant `upsert` code as a tool for the vllm. Combined with the `IEmbeddingGenerator`, this allowed the agent to extract, embed and save the chunks autonomously.


# Search Orchestration
- Extractor / Author / Critic

In the previous example I had two agents, the document-chunk-extracting vision agent and the contract-extracting reasoning agent with chunk search capabilities.

They were run [sequentially](https://learn.microsoft.com/en-us/semantic-kernel/frameworks/agent/agent-orchestration/sequential?pivots=programming-language-csharp), which is one pattern of [agent orchestration](https://learn.microsoft.com/en-us/semantic-kernel/frameworks/agent/agent-orchestration/?pivots=programming-language-csharp).

> The links here are to the Semantic Kernel docs I used, but the functionality is [being added to Microsoft Agent Framework](https://learn.microsoft.com/en-us/agent-framework/user-guide/workflows/orchestrations/overview) too

It was here that I hit a fairly common issue. In normal circumstances you can't combine tool use and structured output when calling an agent. This is simply because forcing a json schema on the output prevents the agent calling tools.

There are various slightly hacky workarounds, such as having a 'thinking output' field on your structured model. Another which I tried here is giving the agent a 'validation' tool with your model as structured input which just returns it unchanged, asking the agent to call it before returning the output.

This worked sometimes, but I would often need to ask the model to try searching again. This was a perfect opportunity to experiment with another common orchestration pattern, [Group Chat](https://learn.microsoft.com/en-us/semantic-kernel/frameworks/agent/agent-orchestration/group-chat?pivots=programming-language-csharp).

More concretely, I would create an agent to act in my place as a 'critic' to the contract 'author'. These can be different LLMs from different providers - it's all abstracted away by the framework.

The critic was instructed to either provide constructive feedback as to what was missing or utter the magic phrase `I approve`. I then had to implement an `AuthorCriticManager` sublass of [RoundRobinGroupChatManager](https://learn.microsoft.com/en-us/dotnet/api/microsoft.agents.ai.workflows.agentworkflowbuilder.roundrobingroupchatmanager?view=agent-framework-dotnet-latest) where `FilterResults` filters for messages by the author and `ShouldTerminate` looks for the magic exit phrase.

This worked pretty well, and on average improved the results. It was funny to watch the models go back and forth in their conversation, although perhaps due to their tiny local nature they often ended up in extended dialogue which wasn't going anwhere. In these cases I was glad I wasn't paying for the tokens. The `RoundRobinGroupChatManager` does have a `MaximumInvocationCount` parameter to prevent complete runaway.

# Single Model, One Shot.
- GPT-5-Mini hosted in AI Foundry


# Responses API
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
