#!/usr/bin/env python3
"""Quick test of Claude Agent SDK."""

import anyio
import os
import sys

# Get API key from argument or environment
api_key = sys.argv[1] if len(sys.argv) > 1 else os.environ.get("ANTHROPIC_API_KEY")
if not api_key:
    print("Usage: python test_sdk.py <api_key>")
    sys.exit(1)

os.environ["ANTHROPIC_API_KEY"] = api_key

from claude_agent_sdk import query, ClaudeAgentOptions

async def test():
    print("Testing Claude Agent SDK...")
    options = ClaudeAgentOptions(max_turns=1)
    async for msg in query(prompt="Say 'SDK works!' and nothing else", options=options):
        print(f"  {type(msg).__name__}: {str(msg)[:200]}")
    print("Done!")

anyio.run(test)
