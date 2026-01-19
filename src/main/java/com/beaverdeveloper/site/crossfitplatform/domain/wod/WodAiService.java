package com.beaverdeveloper.site.crossfitplatform.domain.wod;

import com.beaverdeveloper.site.crossfitplatform.global.config.AiConfig;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpEntity;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestTemplate;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

@Slf4j
@Service
@RequiredArgsConstructor
public class WodAiService {

    private final AiConfig aiConfig;
    private final RestTemplate restTemplate;

    public String suggestWod(String boxName, String type, String requirements) {
        String additionalRequirements = (requirements == null || requirements.isBlank())
                ? "Generate a balanced and varied workout."
                : "User specified requirements: " + requirements;

        String typePrompt = type.equalsIgnoreCase("RANDOM")
                ? "Select an appropriate Crossfit WOD type (AMRAP, FOR_TIME, MAX_WEIGHT, or EMOM) based on the requirements."
                : "WOD type: " + type;

        String prompt = String.format(
                "You are an expert Crossfit coach for the gym '%s'.\n" +
                        "Generate a creative and effective Crossfit WOD.\n" +
                        "%s\n" +
                        "%s\n" +
                        "CRITICAL: You must respond ONLY with a valid JSON object. Do not include any explanation or markdown formatting.\n"
                        +
                        "JSON Schema:\n" +
                        "{\n" +
                        "  \"title\": \"WOD Title\",\n" +
                        "  \"description\": \"Detailed exercises, reps, and sets\",\n" +
                        "  \"type\": \"AMRAP | FOR_TIME | MAX_WEIGHT | EMOM\",\n" +
                        "  \"timeCap\": 1200\n" +
                        "}\n" +
                        "Rules:\n" +
                        "1. Description MUST be in English and very clear.\n" +
                        "2. Ensure all exercises are standard Crossfit movements.\n" +
                        "3. Return only the JSON content.",
                boxName, typePrompt, additionalRequirements);

        Map<String, Object> requestBody = new HashMap<>();
        Map<String, Object> content = new HashMap<>();
        Map<String, String> part = new HashMap<>();
        part.put("text", prompt);
        content.put("parts", List.of(part));
        requestBody.put("contents", List.of(content));

        HttpEntity<Map<String, Object>> entity = new HttpEntity<>(requestBody, createHeaders());

        String url = aiConfig.getBaseUrl() + aiConfig.getModel() + ":generateContent?key=" + aiConfig.getApiKey();
        Map<String, Object> response = restTemplate.postForObject(url, entity, Map.class);

        if (response == null || !response.containsKey("candidates")) {
            throw new RuntimeException("Empty response from Gemini API");
        }

        List<Map<String, Object>> candidates = (List<Map<String, Object>>) response.get("candidates");
        if (candidates == null || candidates.isEmpty()) {
            throw new RuntimeException("No candidates returned from Gemini API");
        }

        Map<String, Object> firstCandidate = candidates.get(0);
        Map<String, Object> contentResponse = (Map<String, Object>) firstCandidate.get("content");
        List<Map<String, Object>> parts = (List<Map<String, Object>>) contentResponse.get("parts");
        String aiText = (String) parts.get(0).get("text");

        return cleanJsonResponse(aiText);
    }

    private HttpHeaders createHeaders() {
        HttpHeaders headers = new HttpHeaders();
        headers.setContentType(MediaType.APPLICATION_JSON);
        return headers;
    }

    private String cleanJsonResponse(String aiText) {
        if (aiText == null)
            return "{}";

        // Find JSON block if it exists
        int startIndex = aiText.indexOf("{");
        int endIndex = aiText.lastIndexOf("}");

        if (startIndex != -1 && endIndex != -1 && endIndex > startIndex) {
            return aiText.substring(startIndex, endIndex + 1);
        }

        return aiText.trim();
    }
}
