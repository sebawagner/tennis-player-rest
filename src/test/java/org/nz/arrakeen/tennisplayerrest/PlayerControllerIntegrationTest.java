package org.nz.arrakeen.tennisplayerrest;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.request.MockMvcRequestBuilders;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.SerializationFeature;
import com.fasterxml.jackson.databind.json.JsonMapper;

import java.sql.Date;
import java.util.HashMap;
import java.util.Map;

import static org.hamcrest.Matchers.*;
import static org.springframework.test.web.servlet.result.MockMvcResultHandlers.print;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@SpringBootTest
@AutoConfigureMockMvc
public class PlayerControllerIntegrationTest {

    @Autowired
    private MockMvc mockMvc;

    private ObjectMapper objectMapper = JsonMapper.builder()
        .configure(SerializationFeature.WRITE_DATES_AS_TIMESTAMPS, false)
        .build();

    @Test
    public void testWelcome() throws Exception {
        mockMvc.perform(MockMvcRequestBuilders
                .get("/welcome")
                .accept(MediaType.APPLICATION_JSON))
                .andDo(print())
                .andExpect(status().isOk())
                .andExpect(content().string("Tennis Player REST API"));
    }

    @Test
    public void testGetAllPlayers() throws Exception {
        mockMvc.perform(MockMvcRequestBuilders
                .get("/players")
                .accept(MediaType.APPLICATION_JSON))
                .andDo(print())
                .andExpect(status().isOk())
                .andExpect(jsonPath("$", hasSize(greaterThan(0))))
                .andExpect(jsonPath("$[0].name", notNullValue()));
    }

    @Test
    public void testGetPlayerById() throws Exception {
        // Test with player ID 1 which should exist in the database
        mockMvc.perform(MockMvcRequestBuilders
                .get("/players/1")
                .accept(MediaType.APPLICATION_JSON))
                .andDo(print())
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.id").value(1))
                .andExpect(jsonPath("$.name", notNullValue()));
    }

    @Test
    public void testGetPlayerNotFound() throws Exception {
        // Test with a player ID that should not exist
        mockMvc.perform(MockMvcRequestBuilders
                .get("/players/999")
                .accept(MediaType.APPLICATION_JSON))
                .andDo(print())
                .andExpect(status().isNotFound())
                .andExpect(jsonPath("$.statusCode").value(404))
                .andExpect(jsonPath("$.message").value("Player with id 999 not found."));
    }

    @Test
    public void testAddPlayer() throws Exception {
        Player newPlayer = new Player("Andy Murray", "Great Britain", Date.valueOf("1987-05-15"), 3);

        mockMvc.perform(MockMvcRequestBuilders
                .post("/players")
                .content(objectMapper.writeValueAsString(newPlayer))
                .contentType(MediaType.APPLICATION_JSON)
                .accept(MediaType.APPLICATION_JSON))
                .andDo(print())
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.name").value("Andy Murray"))
                .andExpect(jsonPath("$.nationality").value("Great Britain"))
                .andExpect(jsonPath("$.titles").value(3))
                .andExpect(jsonPath("$.id", notNullValue()));
    }

    @Test
    public void testAddPlayerWithProfile() throws Exception {
        PlayerProfile profile = new PlayerProfile();
        profile.setTwitter("@andymurray");

        Player newPlayer = new Player("Andy Murray", "Great Britain", Date.valueOf("1987-05-15"), 3);
        newPlayer.setPlayerProfile(profile);

        mockMvc.perform(MockMvcRequestBuilders
                .post("/players")
                .content(objectMapper.writeValueAsString(newPlayer))
                .contentType(MediaType.APPLICATION_JSON)
                .accept(MediaType.APPLICATION_JSON))
                .andDo(print())
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.name").value("Andy Murray"))
                .andExpect(jsonPath("$.playerProfile.twitter").value("@andymurray"))
                .andExpect(jsonPath("$.id", notNullValue()));
    }

    @Test
    public void testUpdatePlayer() throws Exception {
        // First, get an existing player to update
        Player existingPlayer = new Player("Updated Player", "Updated Country", Date.valueOf("1990-01-01"), 5);

        mockMvc.perform(MockMvcRequestBuilders
                .put("/players/1")
                .content(objectMapper.writeValueAsString(existingPlayer))
                .contentType(MediaType.APPLICATION_JSON)
                .accept(MediaType.APPLICATION_JSON))
                .andDo(print())
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.id").value(1))
                .andExpect(jsonPath("$.name").value("Updated Player"))
                .andExpect(jsonPath("$.nationality").value("Updated Country"))
                .andExpect(jsonPath("$.titles").value(5));
    }

    @Test
    public void testUpdatePlayerWithInvalidData() throws Exception {
        // Create player with missing name
        Player invalidPlayer = new Player("", "Some Country", Date.valueOf("1990-01-01"), 5);

        mockMvc.perform(MockMvcRequestBuilders
                .put("/players/1")
                .content(objectMapper.writeValueAsString(invalidPlayer))
                .contentType(MediaType.APPLICATION_JSON)
                .accept(MediaType.APPLICATION_JSON))
                .andDo(print())
                .andExpect(status().isBadRequest())
                .andExpect(content().string("All player attributes (name, nationality, birthDate, titles) must be provided and valid"));

        // Test with negative titles
        invalidPlayer.setName("Valid Name");
        invalidPlayer.setTitles(-1);

        mockMvc.perform(MockMvcRequestBuilders
                .put("/players/1")
                .content(objectMapper.writeValueAsString(invalidPlayer))
                .contentType(MediaType.APPLICATION_JSON)
                .accept(MediaType.APPLICATION_JSON))
                .andDo(print())
                .andExpect(status().isBadRequest());
    }

    @Test
    public void testUpdatePlayerNotFound() throws Exception {
        Player player = new Player("Not Found", "Nowhere", Date.valueOf("1990-01-01"), 0);

        mockMvc.perform(MockMvcRequestBuilders
                .put("/players/999")
                .content(objectMapper.writeValueAsString(player))
                .contentType(MediaType.APPLICATION_JSON)
                .accept(MediaType.APPLICATION_JSON))
                .andDo(print())
                .andExpect(status().isNotFound())
                .andExpect(jsonPath("$.statusCode").value(404))
                .andExpect(jsonPath("$.message").value("Player with id 999 not found."));
    }

    @Test
    public void testPartialUpdate() throws Exception {
        Map<String, Object> updates = new HashMap<>();
        updates.put("name", "Partially Updated Name");
        updates.put("titles", 10);

        mockMvc.perform(MockMvcRequestBuilders
                .patch("/players/1")
                .content(objectMapper.writeValueAsString(updates))
                .contentType(MediaType.APPLICATION_JSON)
                .accept(MediaType.APPLICATION_JSON))
                .andDo(print())
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.id").value(1))
                .andExpect(jsonPath("$.name").value("Partially Updated Name"))
                .andExpect(jsonPath("$.titles").value(10));
    }

    @Test
    public void testPartialUpdateNotFound() throws Exception {
        Map<String, Object> updates = new HashMap<>();
        updates.put("name", "Not Found");

        mockMvc.perform(MockMvcRequestBuilders
                .patch("/players/999")
                .content(objectMapper.writeValueAsString(updates))
                .contentType(MediaType.APPLICATION_JSON)
                .accept(MediaType.APPLICATION_JSON))
                .andDo(print())
                .andExpect(status().isNotFound())
                .andExpect(jsonPath("$.statusCode").value(404))
                .andExpect(jsonPath("$.message").value("Player with id 999 not found."));
    }

    @Test
    public void testUpdateTitles() throws Exception {
        int newTitles = 15;

        mockMvc.perform(MockMvcRequestBuilders
                .patch("/players/1/titles")
                .content(String.valueOf(newTitles))
                .contentType(MediaType.APPLICATION_JSON)
                .accept(MediaType.APPLICATION_JSON))
                .andDo(print())
                .andExpect(status().isOk());

        // Verify the change by getting the player
        mockMvc.perform(MockMvcRequestBuilders
                .get("/players/1")
                .accept(MediaType.APPLICATION_JSON))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.titles").value(15));
    }

    @Test
    public void testDeletePlayer() throws Exception {
        // First, create a player to delete
        Player playerToDelete = new Player("To Be Deleted", "Nowhere", Date.valueOf("1990-01-01"), 0);

        String responseContent = mockMvc.perform(MockMvcRequestBuilders
                .post("/players")
                .content(objectMapper.writeValueAsString(playerToDelete))
                .contentType(MediaType.APPLICATION_JSON)
                .accept(MediaType.APPLICATION_JSON))
                .andExpect(status().isCreated())
                .andReturn().getResponse().getContentAsString();

        // Extract the ID of the created player
        Player createdPlayer = objectMapper.readValue(responseContent, Player.class);
        int playerId = createdPlayer.getId();

        // Delete the player
        mockMvc.perform(MockMvcRequestBuilders
                .delete("/players/" + playerId)
                .accept(MediaType.APPLICATION_JSON))
                .andDo(print())
                .andExpect(status().isOk())
                .andExpect(content().string("Player with id " + playerId + " deleted"));

        // Verify the player is deleted
        mockMvc.perform(MockMvcRequestBuilders
                .get("/players/" + playerId)
                .accept(MediaType.APPLICATION_JSON))
                .andExpect(status().isNotFound());
    }

    @Test
    public void testDeletePlayerNotFound() throws Exception {
        mockMvc.perform(MockMvcRequestBuilders
                .delete("/players/999")
                .accept(MediaType.APPLICATION_JSON))
                .andDo(print())
                .andExpect(status().isNotFound())
                .andExpect(jsonPath("$.statusCode").value(404))
                .andExpect(jsonPath("$.message").value("Player with id 999 not found."));
    }
}
