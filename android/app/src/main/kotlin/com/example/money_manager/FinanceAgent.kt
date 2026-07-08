package com.example.money_manager

import com.google.adk.kt.agents.Instruction
import com.google.adk.kt.agents.LlmAgent
import com.google.adk.kt.annotations.Param
import com.google.adk.kt.annotations.Tool
import com.google.adk.kt.models.Gemini

class FinanceService {
    @Tool
    fun analyzeSpending(
        @Param("The category of spending to analyze, e.g. 'Food', 'Transport'") category: String
    ): Map<String, String> {
        // Mock data for the sake of the example
        return mapOf(
            "category" to category,
            "status" to "Spending is normal.",
            "total_spent" to "$150.00"
        )
    }
}

object FinanceAgent {
    @JvmField
    val rootAgent = LlmAgent(
        name = "finance_agent",
        description = "Analyzes personal finance data and answers questions.",
        model = Gemini(
            name = "gemini-flash-latest",
            // For production, use Firebase AI Logic or custom backend
            apiKey = System.getenv("GOOGLE_API_KEY") ?: "mock-key-for-local-testing"
        ),
        instruction = Instruction(
            "You are a helpful assistant that analyzes personal finances. "
                + "Use the 'analyzeSpending' tool when asked about spending in a category."
        ),
        tools = FinanceService().generatedTools(),
    )
}
