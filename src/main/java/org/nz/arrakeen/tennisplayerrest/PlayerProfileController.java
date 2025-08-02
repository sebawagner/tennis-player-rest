package org.nz.arrakeen.tennisplayerrest;

import java.util.List;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/profiles")
public class PlayerProfileController {

    @Autowired
    PlayerProfileService service;

    @GetMapping
    public List<PlayerProfile> allPlayerProfiles() {
        return service.allPlayerProfiles();
    }

    @GetMapping("/{id}")
    public PlayerProfile getPlayerProfile(@PathVariable int id){
        return service.getPlayerProfile(id);
    }

    @PostMapping
    public PlayerProfile addPlayerProfile(@RequestBody PlayerProfile playerProfile) {
        return service.addPlayerProfile(playerProfile);
    }

    @DeleteMapping("/{id}")
    public void deletePlayerProfile(@PathVariable int id) {
        service.deletePlayerProfile(id);
    }
}