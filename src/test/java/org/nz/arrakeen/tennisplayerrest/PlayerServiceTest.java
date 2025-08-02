package org.nz.arrakeen.tennisplayerrest;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.sql.Date;
import java.util.Arrays;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyInt;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
public class PlayerServiceTest {

    @Mock
    private PlayerRepository playerRepository;

    @InjectMocks
    private PlayerService playerService;

    private Player player1;
    private Player player2;
    private PlayerProfile profile1;

    @BeforeEach
    public void setUp() {
        // Create a player profile
        profile1 = new PlayerProfile();
        profile1.setTwitter("@player1");

        // Create test players
        player1 = new Player("Roger Federer", "Switzerland", Date.valueOf("1981-08-08"), 20);
        player1.setId(1);
        player1.setPlayerProfile(profile1);

        player2 = new Player("Rafael Nadal", "Spain", Date.valueOf("1986-06-03"), 22);
        player2.setId(2);
    }

    @Test
    public void testGetAllPlayers() {
        // Arrange
        List<Player> players = Arrays.asList(player1, player2);
        when(playerRepository.findAllOrderedById()).thenReturn(players);

        // Act
        List<Player> result = playerService.getAllPlayers();

        // Assert
        assertEquals(2, result.size());
        assertEquals("Roger Federer", result.get(0).getName());
        assertEquals("Rafael Nadal", result.get(1).getName());
        verify(playerRepository, times(1)).findAllOrderedById();
    }

    @Test
    public void testGetPlayerSuccess() {
        // Arrange
        when(playerRepository.findById(1)).thenReturn(Optional.of(player1));

        // Act
        Player result = playerService.getPlayer(1);

        // Assert
        assertNotNull(result);
        assertEquals(1, result.getId());
        assertEquals("Roger Federer", result.getName());
        assertEquals("Switzerland", result.getNationality());
        assertEquals(20, result.getTitles());
        assertEquals("@player1", result.getPlayerProfile().getTwitter());
        verify(playerRepository, times(1)).findById(1);
    }

    @Test
    public void testGetPlayerNotFound() {
        // Arrange
        when(playerRepository.findById(999)).thenReturn(Optional.empty());

        // Act & Assert
        PlayerNotFoundException exception = assertThrows(
            PlayerNotFoundException.class,
            () -> playerService.getPlayer(999)
        );
        assertEquals("Player with id 999 not found.", exception.getMessage());
        verify(playerRepository, times(1)).findById(999);
    }

    @Test
    public void testAddPlayerWithoutProfile() {
        // Arrange
        Player newPlayer = new Player("Novak Djokovic", "Serbia", Date.valueOf("1987-05-22"), 21);
        Player savedPlayer = new Player("Novak Djokovic", "Serbia", Date.valueOf("1987-05-22"), 21);
        savedPlayer.setId(3);

        when(playerRepository.save(any(Player.class))).thenReturn(savedPlayer);

        // Act
        Player result = playerService.addPlayer(newPlayer);

        // Assert
        assertNotNull(result);
        assertEquals(3, result.getId());
        assertEquals("Novak Djokovic", result.getName());
        assertEquals("Serbia", result.getNationality());
        assertEquals(21, result.getTitles());
        verify(playerRepository, times(1)).save(any(Player.class));
    }

    @Test
    public void testAddPlayerWithProfile() {
        // Arrange
        PlayerProfile profile = new PlayerProfile();
        profile.setTwitter("@djokovic");

        Player newPlayer = new Player("Novak Djokovic", "Serbia", Date.valueOf("1987-05-22"), 21);
        newPlayer.setPlayerProfile(profile);

        Player savedPlayer = new Player("Novak Djokovic", "Serbia", Date.valueOf("1987-05-22"), 21);
        savedPlayer.setId(3);
        savedPlayer.setPlayerProfile(profile);

        when(playerRepository.save(any(Player.class))).thenReturn(savedPlayer);

        // Act
        Player result = playerService.addPlayer(newPlayer);

        // Assert
        assertNotNull(result);
        assertEquals(3, result.getId());
        assertEquals("Novak Djokovic", result.getName());
        assertEquals("@djokovic", result.getPlayerProfile().getTwitter());
        verify(playerRepository, times(1)).save(any(Player.class));
    }

    @Test
    public void testUpdatePlayerSuccess() {
        // Arrange
        Player updatedPlayer = new Player("Roger Updated", "Switzerland", Date.valueOf("1981-08-08"), 21);

        when(playerRepository.findById(1)).thenReturn(Optional.of(player1));
        when(playerRepository.save(any(Player.class))).thenAnswer(invocation -> {
            Player savedPlayer = invocation.getArgument(0);
            return savedPlayer; // Return the updated player
        });

        // Act
        Player result = playerService.updatePlayer(1, updatedPlayer);

        // Assert
        assertNotNull(result);
        assertEquals(1, result.getId());
        assertEquals("Roger Updated", result.getName());
        assertEquals(21, result.getTitles());
        verify(playerRepository, times(1)).findById(1);
        verify(playerRepository, times(1)).save(any(Player.class));
    }

    @Test
    public void testUpdatePlayerNotFound() {
        // Arrange
        Player updatedPlayer = new Player("Unknown Player", "Unknown", Date.valueOf("2000-01-01"), 0);
        when(playerRepository.findById(999)).thenReturn(Optional.empty());

        // Act & Assert
        PlayerNotFoundException exception = assertThrows(
            PlayerNotFoundException.class,
            () -> playerService.updatePlayer(999, updatedPlayer)
        );
        assertEquals("Player with id 999 not found.", exception.getMessage());
        verify(playerRepository, times(1)).findById(999);
        verify(playerRepository, never()).save(any(Player.class));
    }

    @Test
    public void testPatchPlayerSuccess() {
        // Arrange
        Map<String, Object> playerPatch = new HashMap<>();
        playerPatch.put("name", "Roger Patched");
        playerPatch.put("titles", 21);

        when(playerRepository.findById(1)).thenReturn(Optional.of(player1));
        when(playerRepository.save(any(Player.class))).thenAnswer(invocation -> {
            Player savedPlayer = invocation.getArgument(0);
            return savedPlayer;
        });

        // Act
        Player result = playerService.patch(1, playerPatch);

        // Assert
        assertNotNull(result);
        assertEquals(1, result.getId());
        assertEquals("Roger Patched", result.getName());
        assertEquals(21, result.getTitles());
        // Unchanged fields should remain the same
        assertEquals("Switzerland", result.getNationality());
        verify(playerRepository, times(1)).findById(1);
        verify(playerRepository, times(1)).save(any(Player.class));
    }

    @Test
    public void testPatchPlayerNotFound() {
        // Arrange
        Map<String, Object> playerPatch = new HashMap<>();
        playerPatch.put("name", "Unknown Player");

        when(playerRepository.findById(999)).thenReturn(Optional.empty());

        // Act & Assert
        PlayerNotFoundException exception = assertThrows(
            PlayerNotFoundException.class,
            () -> playerService.patch(999, playerPatch)
        );
        assertEquals("Player with id 999 not found.", exception.getMessage());
        verify(playerRepository, times(1)).findById(999);
        verify(playerRepository, never()).save(any(Player.class));
    }

    @Test
    public void testUpdateTitles() {
        // Arrange
        doNothing().when(playerRepository).updateTitles(anyInt(), anyInt());

        // Act
        playerService.updateTitles(1, 25);

        // Assert
        verify(playerRepository, times(1)).updateTitles(1, 25);
    }

    @Test
    public void testDeletePlayerSuccess() {
        // Arrange
        when(playerRepository.findById(1)).thenReturn(Optional.of(player1));
        doNothing().when(playerRepository).delete(any(Player.class));

        // Act
        String result = playerService.deletePlayer(1);

        // Assert
        assertEquals("Player with id 1 deleted", result);
        verify(playerRepository, times(1)).findById(1);
        verify(playerRepository, times(1)).delete(player1);
    }

    @Test
    public void testDeletePlayerNotFound() {
        // Arrange
        when(playerRepository.findById(999)).thenReturn(Optional.empty());

        // Act & Assert
        PlayerNotFoundException exception = assertThrows(
            PlayerNotFoundException.class,
            () -> playerService.deletePlayer(999)
        );
        assertEquals("Player with id 999 not found.", exception.getMessage());
        verify(playerRepository, times(1)).findById(999);
        verify(playerRepository, never()).delete(any(Player.class));
    }
}
