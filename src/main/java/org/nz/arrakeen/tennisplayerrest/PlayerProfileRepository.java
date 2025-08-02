package org.nz.arrakeen.tennisplayerrest;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface PlayerProfileRepository extends JpaRepository<PlayerProfile, Integer>{

}
