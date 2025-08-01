package org.nz.arrakeen.tennisplayerrest;

import org.springframework.data.jpa.repository.JpaRepository;

public interface PlayerRepository extends JpaRepository <Player, Integer> {

}
