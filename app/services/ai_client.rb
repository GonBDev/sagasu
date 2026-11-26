class AiClient # Centralize provider configuration and chat creation.
  def self.chat # Start a fresh chat for each AI request.
    context = RubyLLM.context do |config| # Configure this request without changing global settings.
      config.openai_api_key = ENV.fetch("OPENAI_API_KEY") # Read the credential when an AI request starts.
    end # Keep ordinary Rails boot independent of the OpenAI credential.

    context.chat( # Let RubyLLM build the provider-specific chat.
      provider: ENV.fetch("SAGASU_AI_PROVIDER", "openai"), # Default to the only configured provider.
      model: ENV.fetch("SAGASU_AI_MODEL", "gpt-4.1-mini") # Use one default for structured grouping.
    ) # Return the chat so the caller can set instructions and a schema.
  end # Finish chat creation.
end # Finish the shared AI client.
