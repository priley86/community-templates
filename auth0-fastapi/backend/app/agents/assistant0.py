from langgraph.prebuilt import ToolNode, create_react_agent
from langchain_google_genai import ChatGoogleGenerativeAI

from app.agents.tools.google_calendar import list_upcoming_events
from datetime import date

tools = [list_upcoming_events]

# Initialize the LLM
# This template supports both Google Gemini and OpenAI models
# 
# For Google Gemini (default):
llm = ChatGoogleGenerativeAI(model="gemini-2.0-flash-exp")  # or "gemini-1.5-pro", "gemini-1.5-flash", etc.
#
# For OpenAI (see GEMINI.md for setup):
# from langchain_openai import ChatOpenAI
# llm = ChatOpenAI(model="gpt-4o-mini")  # or "gpt-4o", "gpt-4-turbo", etc.

def get_prompt():
    today_str = date.today().strftime('%Y-%m-%d')
    return (
        f"You are a personal assistant named Assistant0. You are a helpful assistant that can answer questions and help with tasks. "
        f"Today's date is {today_str}. You have access to a set of tools, use the tools as needed to answer the user's question. "
        f"Render the email body as a markdown block, do not wrap it in code blocks."
    )

agent = create_react_agent(
    llm,
    tools=ToolNode(tools, handle_tool_errors=False),
    prompt=get_prompt(),
)
