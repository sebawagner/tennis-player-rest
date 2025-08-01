package org.nz.arrakeen.tennisplayerrest;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.Optional;

@Service
public class PlayerService {
    @Autowired
    private PlayerRepository repo;

    //method to return all players
    public List<Player> getAllPlayers() {
        return repo.findAll();
    }

    //method to find player by id
    public Player getPlayer(int id) {

        Optional<Player> tempPlayer = repo.findById(id);

        Player p = null;

        //if the Optional has a value, assign it to p
        if(tempPlayer.isPresent())
            p = tempPlayer.get();

        //if value is not found, throw a runtime exception
        else
            throw new RuntimeException("Player with id "+ id + " not found.");

        return p;
    }


    //method to add player
    public Player addPlayer(Player p) {
        // Use the direct save approach, but create a new instance without an ID
        Player player = new Player(
            p.getName(),
            p.getNationality(),
            p.getBirthDate(),
            p.getTitles()
        );
        // Let JPA/Hibernate handle the ID generation
        return repo.save(player);
    }
}
