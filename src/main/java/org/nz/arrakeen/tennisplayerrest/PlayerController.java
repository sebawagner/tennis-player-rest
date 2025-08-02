package org.nz.arrakeen.tennisplayerrest;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@RestController
public class PlayerController {

    @Autowired
    PlayerService service;

    @GetMapping("/welcome")
    public String welcome() {
        return "Tennis Player REST API";
    }

    @GetMapping("/players")
    public List<Player> getAllPlayers() {
        return service.getAllPlayers();
    }

    @GetMapping("/players/{id}")
    public Player getPlayer(@PathVariable int id) {
        return service.getPlayer(id);
    }

    @PostMapping("/players")
    public ResponseEntity<Player> addPlayer(@RequestBody Player player) {
        Player newPlayer = service.addPlayer(player);
        return new ResponseEntity<>(newPlayer, HttpStatus.CREATED);
    }

    @PutMapping("/players/{id}")
    public ResponseEntity<?> updatePlayer(@RequestBody Player player, @PathVariable int id) {
        // Validate that all required fields are present
        if (player.getName() == null || player.getName().trim().isEmpty() ||
            player.getNationality() == null || player.getNationality().trim().isEmpty() ||
            player.getBirthDate() == null ||
            player.getTitles() < 0) {

            return new ResponseEntity<>("All player attributes (name, nationality, birthDate, titles) must be provided and valid",
                                       HttpStatus.BAD_REQUEST);
        }

        // If validation passes, proceed with the update
        Player updatedPlayer = service.updatePlayer(id, player);
        return new ResponseEntity<>(updatedPlayer, HttpStatus.OK);
    }

    @PatchMapping("/players/{id}")
    public Player partialUpdate( @PathVariable int id, @RequestBody Map<String, Object> playerPatch) {
        return service.patch(id, playerPatch);
    }

    @PatchMapping("/players/{id}/titles")
    public void updateTitles(@PathVariable int id, @RequestBody int titles) {
        service.updateTitles(id, titles);
    }

    @DeleteMapping("/players/{id}")
    public String deletePlayer(@PathVariable int id) {
        return service.deletePlayer(id);
    }

}
