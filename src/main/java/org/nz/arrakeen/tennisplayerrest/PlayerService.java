package org.nz.arrakeen.tennisplayerrest;

import java.lang.reflect.Field;
import java.util.List;
import java.util.Map;
import java.util.Optional;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.util.ReflectionUtils;

import jakarta.transaction.Transactional;

@Service
public class PlayerService {
    @Autowired
    private PlayerRepository repo;

    //method to return all players
    public List<Player> getAllPlayers() {
        return repo.findAllOrderedById();
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
            throw new PlayerNotFoundException("Player with id "+ id + " not found.");


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
        if (p.getPlayerProfile() != null) {
            player.setPlayerProfile(p.getPlayerProfile());
        }
        // Let JPA/Hibernate handle the ID generation
        return repo.save(player);
    }

    //method to update player
    public Player updatePlayer(int id, Player p) {
        //get player object by Id
        Optional<Player> tempPlayer = repo.findById(id);

        Player player = null;

        //if the Optional has a value, assign it to p
        if(tempPlayer.isPresent())
            player = tempPlayer.get();
        else
            throw new PlayerNotFoundException("Player with id "+ id + " not found.");

        //update player information in database
        player.setName(p.getName());
        player.setNationality(p.getNationality());
        player.setBirthDate(p.getBirthDate());
        player.setTitles(p.getTitles());

        //save updates
        return repo.save(player);
    }

    //partial update
    public Player patch( int id, Map<String, Object> playerPatch) {

        Optional<Player> player = repo.findById(id);

        if(player.isPresent()) {
            playerPatch.forEach( (key, value) -> {
                Field field = ReflectionUtils.findField(Player.class, key);
                ReflectionUtils.makeAccessible(field);
                ReflectionUtils.setField(field, player.get(), value);
            });
        } else {
            throw new PlayerNotFoundException("Player with id " + id + " not found.");
        }
        return repo.save(player.get());
    }

    @Transactional
    public void updateTitles(int id, int titles) {
        repo.updateTitles(id, titles);
    }

    //delete a player
    public String deletePlayer(int id) {
        Optional<Player> tempPlayer = repo.findById(id);

        if(tempPlayer.isEmpty()) {
            throw new PlayerNotFoundException("Player with id "+ id + " not found.");
        }

        repo.delete(tempPlayer.get());
        return "Player with id "+ id +" deleted";
    }
}
