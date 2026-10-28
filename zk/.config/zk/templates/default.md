---
title: {{json title}}
date: {{format-date now}} {{format-date now "time"}}
tags: {{#if extra.tags}}{{extra.tags}}{{/if}}
---

# {{title}}

{{#if extra.tags}}{{extra.tags}}{{/if}}

{{content}}
