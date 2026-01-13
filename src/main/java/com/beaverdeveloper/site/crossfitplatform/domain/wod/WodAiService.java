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

    private static final String GEMINI_URL = "https://generativelanguage.googleapis.com/v1beta/models/gemini-pro:generateContent?key=";

    public String suggestWod(String boxName, String type) {
        String prompt = String.format(
                "You are an expert Crossfit coach for the gym '%s'. " +
                        "Generate a creative and effective Crossfit WOD of type '%s'. " +
                        "Provide the response in JSON format exactly as follows: " +
                        "{\"title\": \"WOD Title\", \"description\": \"Detailed exercises and reps\", \"type\": \"%s\", \"timeCap\": 1200}. "
                        +
                        "Make the description clear and professional in Korean.",
                boxName, type, type);

        Map<String, Object> requestBody = new HashMap<>();
        Map<String, Object> content = new HashMap<>();
        Map<String, String> part = new HashMap<>();
        part.put("text", prompt);
        content.put("parts", List.of(part));
        requestBody.put("contents", List.of(content));

        HttpHeaders headers = new HttpHeaders();
        headers.setContentType(MediaType.APPLICATION_JSON);

        HttpEntity<Map<String, Object>> entity = new HttpEntity<>(requestBody, headers);

        try {
            String url = GEMINI_URL + aiConfig.getApiKey();
            Map<String, Object> response = restTemplate.postForObject(url, entity, Map.class);

            List<Map<String, Object>> candidates = (List<Map<String, Object>>) response.get("candidates");
            Map<String, Object> firstCandidate = candidates.get(0);
            Map<String, Object> contentResponse = (Map<String, Object>) firstCandidate.get("content");
            List<Map<String, Object>> parts = (List<Map<String, Object>>) contentResponse.get("parts");
            String aiText = (String) parts.get(0).get("text");

            return aiText.replaceAll("```json", "").replaceAll("```", "").trim();
        } catch (Exception e) {
            log.error("Gemini API call failed", e);
            return "{\"title\": \"Error\", \"description\": \"AI 추천을 가져오는데 실패했습니다.\", \"type\": \"AMRAP\", \"timeCap\": 0}";
        }
    }
}
