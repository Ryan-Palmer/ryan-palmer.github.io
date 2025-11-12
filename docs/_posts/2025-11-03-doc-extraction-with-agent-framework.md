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

There is an awesome [series of videos](https://www.youtube.com/playlist?list=PLhGl0l5La4sYXjYOBv7h9l7x6qNuW34Cx) on YouTube which show practical examples of migration process from SK and how to use all the features of the new framework. I'd highly recommend it as your first point of call for any more information on the approaches discussed in this blog.


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

Inspection of the chunks in the vector store showed that they were mostly well extracted, labelled and described.

To further speed up the chunk extraction process I added two new features:
- Automation of the PDF -> Image sequence conversion with [PDFtoImage](https://github.com/sungaila/PDFtoImage)
- Exposing of the Qdrant `upsert` code as a tool for the vllm. 

> In Semantic Kernel this was achieved by decorating a method with the [KernelFunction](https://learn.microsoft.com/en-us/semantic-kernel/concepts/ai-services/chat-completion/function-calling/?pivots=programming-language-csharp#example-ordering-a-pizza) attribute. In Microsoft Agent Framework you [wrap a static method in `AIFunctionFactory.Create()`](https://learn.microsoft.com/en-us/agent-framework/tutorials/agents/function-tools?pivots=programming-language-csharp#create-the-agent-with-function-tools).

Combined with the `IEmbeddingGenerator`, this allowed the agent to extract, embed and save the chunks autonomously.


# Search Orchestration

In the previous example I had two agents, the document-chunk-extracting vision agent and the contract-extracting reasoning agent with chunk search capabilities. They were run [sequentially](https://learn.microsoft.com/en-us/semantic-kernel/frameworks/agent/agent-orchestration/sequential?pivots=programming-language-csharp), which is one pattern of [agent orchestration](https://learn.microsoft.com/en-us/semantic-kernel/frameworks/agent/agent-orchestration/?pivots=programming-language-csharp).

> The links here are to the Semantic Kernel docs I used, but the functionality is [being added to Microsoft Agent Framework](https://learn.microsoft.com/en-us/agent-framework/user-guide/workflows/orchestrations/overview) too

It was here that I hit a fairly common issue. In normal circumstances you can't combine tool use and structured output when calling an agent. This is simply because forcing a JSON schema on the output prevents the agent calling tools. There are various slightly hacky workarounds, such as having a 'thinking output' field on your structured model. Another, which I tried here, is giving the agent a 'validation' tool with your model as structured input which just returns it unchanged. You can then ask the agent to call it before returning the output.

This worked sometimes, but I would often need to ask the model to try searching again. This was a perfect opportunity to experiment with another common orchestration pattern, [Group Chat](https://learn.microsoft.com/en-us/semantic-kernel/frameworks/agent/agent-orchestration/group-chat?pivots=programming-language-csharp). More concretely, I would create an agent to act in my place as a 'critic' to the contract 'author'. These can be different LLMs from different providers - it's all abstracted away by the framework.

The critic was instructed to either provide constructive feedback as to what was missing or utter the magic phrase `I approve`. The group chat orchestration requires a [GroupChatManager](https://learn.microsoft.com/en-us/semantic-kernel/frameworks/agent/agent-orchestration/group-chat?pivots=programming-language-csharp#customize-the-group-chat-manager). I re-implemented the sealed [AuthorCriticManager](https://github.com/markwallace-microsoft/semantic-kernel/blob/1ccdd1e649dd69bea6f797a3ad74e65f5228e7c0/dotnet/samples/GettingStartedWithAgents/Orchestration/Step03_GroupChat.cs#L92) class, which is itself a subclass of [RoundRobinGroupChatManager](https://learn.microsoft.com/en-us/dotnet/api/microsoft.agents.ai.workflows.agentworkflowbuilder.roundrobingroupchatmanager?view=agent-framework-dotnet-latest) with two simple overloads:
- `FilterResults` filters for messages by the author
- `ShouldTerminate` looks for the magic `I approve` exit phrase (or reaching the `MaximumInvocationCount` specified on the `GroupChatManager`).

This worked pretty well, and on average improved the results. It was funny to watch the models go back and forth in their conversation, although perhaps due to their tiny local nature they often ended up in extended dialogue which wasn't going anywhere. In these cases I was glad I wasn't paying for the tokens (although of course I could have limited the `MaximumInvocationCount` as stated above).


# Cloud Models

At this point I had explored the SDKs, APIs, orchestrations, tools and discovered approaches that worked most of the time with small local models. It seemed an appropriate time to explore larger, commercial models to see what they could achieve and also what challenges might be involved.

The first considerations were 
- Where can I find them?
- How much will it cost?

I had noticed the recently released [Github Models](https://docs.github.com/en/github-models) service which allows you to experiment with a large selection of models for free with restrictions or derestricted with billing linked to your Github account. This seemed like a low barrier to entry, plus the [AI Toolkit](https://learn.microsoft.com/en-us/windows/ai/toolkit/) plugin in VSCode made it easy to explore the catalogue.

I decided to start with the simplest thing that could possibly work, on the smallest model available (within reason, given cost vs performance etc etc). Could [GPT-5 mini](https://github.com/marketplace/models/azure-openai/gpt-5-mini) use its vision capabilities to extract the entire contract in one shot from the images alone, negating the need for any extraction / chunking / RAG / tools / orchestration etc?

I had to turn on billing as the multiple pages images exceeded the free limits on context size, but to my delight the model was correct on every field. I tried it with a different contract type and again it was correct. This was of course great news as it meant we needed to use very few tokens compared to the more complex approaches, plus there was less to maintain and equally less to go wrong.


# Responses API

Whilst looking at the OpenAPI documentation, I found a section explaining that you can [upload PDFs directly](https://platform.openai.com/docs/guides/pdf-files?api-mode=chat)! Open API [extract both images *and* text](https://platform.openai.com/docs/guides/pdf-files?api-mode=chat#how-it-works) from the document and feed it to the model for you. This would simplify my code and provide even more context to the model, a double win. 

There was only one problem - PDF upload requires use of the [Responses API](https://platform.openai.com/docs/api-reference/responses). This is OpenAI's most up to date API, replacing the (still widely used) ChatCompletions and Assistants APIs which came before it. Unfortunately, Github Models [only supports the Chat Completions](https://docs.github.com/en/rest/models/inference?apiVersion=2022-11-28#run-an-inference-request) API. In addition to this, I had been authenticating with a Personal Access Token which was fine for testing but not an ideal solution as we move towards production.

For both of these reasons, I decided to look at Microsoft's [AI Foundry](https://learn.microsoft.com/en-us/azure/ai-foundry/what-is-azure-ai-foundry) enterprise offering. This both [supports the Responses API](https://learn.microsoft.com/en-us/azure/ai-foundry/openai/how-to/responses?tabs=python-key) and allows authenticating with [Azure credentials](https://learn.microsoft.com/en-us/azure/ai-foundry/quickstarts/get-started-code?tabs=csharp#set-up-your-environment) via e.g. the CLI or, eventually, managed identity in App Service. It's also tied into the billing for the rest of our Azure services and has full featured [VSCode integration](https://learn.microsoft.com/en-us/azure/ai-foundry/how-to/develop/get-started-projects-vs-code), so acted as a great replacement for Github Models. 

Once I provisioned the GPT 5 mini model in AI Foundry and switched my connection details, I was able to create an [OpenAIResponseClient](https://learn.microsoft.com/en-us/dotnet/api/azure.ai.openai.azureopenaiclient.getopenairesponseclient?view=azure-dotnet-preview) and directly submit a PDF as a byte array inside a [DataContent](https://learn.microsoft.com/en-us/agent-framework/user-guide/agents/running-agents?pivots=programming-language-csharp#message-types) message. I once again found very strong performance, with the simple architecture resulting in a low token count and very reasonable cost of a fraction of a penny per document.

# Conclusion

It's never been easier to get up and running with your own agent-based software. There are so many powerful small models and orchestration frameworks, convenient local tooling and cheap cloud hosting options that you can go from idea to prototype in no time. With that said, there are so many options and ways of tackling the problem that it can feel overwhelming. That's before you even consider how quickly the ecosystem is developing and changing underneath you.

In these situations, as in most other software development challenges, I find the best approach is to balance exploration and exploitation to understand the landscape and make meaningful progress towards your goals. Focus on the activities which will [resolve the most amount of uncertainty for the least amount of risk](https://www.youtube.com/watch?v=bk_xCikDUDQ), then take the simplest path possible given what you've learnt.

